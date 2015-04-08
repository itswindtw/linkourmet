# Sinatra
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'
require 'slim'

# bcrypt
require 'bcrypt'

# Facebook graph API
require 'koala'

# Twitter
require 'twitter_oauth'

# Solid
require 'facebook_grabber'
require 'twitter_grabber'
require 'solid_secret'

class Solid < Sinatra::Base
  configure do
    enable :logging
    enable :sessions

    set :root, BASE_PATH
    set :session_secret, SolidSecret::SESSION_SECRET

    register Sinatra::Reloader if development?
  end

  helpers Sinatra::JSON
  helpers do
    def set_current_user(user)
      session[:user_id] = user.id
    end

    def current_user
      return nil unless session[:user_id]

      User.where(id: session[:user_id]).first
    end

    def logged_in?
      session[:user_id] != nil
    end

    def service_ready?
      logged_in? && current_user.social_services.length > 0
    end

    def fetch_links_for(user_id)
      uri = URI("#{API_ENDPOINT}/getRec?user=#{user_id}")
      res = Net::HTTP.get_response(uri)
      logger.info("#{uri}: #{res}")

      return nil unless res.code.to_i == 200

      JSON.parse(res.body)['reclinks']
    end

    def host_with_port
      standard_port = if request.scheme == 'http' then 80 else 443 end
      port_string = if request.port == standard_port then '' else ":#{request.port}" end

      "#{request.scheme}://#{request.host}#{port_string}"
    end
  end

  #
  get '/' do
    return redirect to('/auth') unless logged_in?

    @social_services = current_user.social_services.map(&:provider)
    slim :index
  end

  get '/links' do
    return redirect to('/') unless service_ready?

    slim :links
  end

  get '/auth' do
    return redirect to('/') if logged_in?

    @user = User.new
    slim :auth
  end

  post '/signin' do
    @user = User.where(email: params[:inputEmail]).first

    if @user && BCrypt::Password.new(@user.password) == params[:inputPassword]
      set_current_user(@user)
      redirect to('/')
    else
      @user ||= User.new(email: params[:inputEmail])
      slim :auth
    end
  end

  post '/signup' do
    @user = User.new(email: params[:inputEmail], password: BCrypt::Password.create(params[:inputPassword]))

    if @user.valid?
      @user.save
      session[:user_id] = @user.id
      redirect to('/')
    else
      slim :auth
    end
  end

  #

  # TODO: check valid login status
  post '/api/auth/facebook' do
    facebook_user_id = params[:userID].to_s
    access_token = params[:accessToken].to_s

    graph = Koala::Facebook::API.new(access_token)

    # Validate user_id and token
    profile = graph.get_object('me')
    return 400 unless profile['id'] == facebook_user_id

    # Store/update this social service in database
    service = current_user.facebook_service
    if service
      service.update(access_token: access_token, active: true)
    else
      current_user.add_social_service(
        provider: 'facebook', access_token: access_token)
    end

    current_user.increment_active_workers!

    # Enqueue data grabber
    Resque.enqueue(FacebookGrabber, current_user.id, access_token)

    201
  end

  delete '/api/auth/facebook' do
    service = current_user.facebook_service
    service.update(active: false) if service

    current_user.decrement_active_workers!
    200
  end


  before '/api/auth/twitter*' do
    @client = TwitterOAuth::Client.new(
      consumer_key: SolidSecret::TWITTER_CONSUMER_KEY,
      consumer_secret: SolidSecret::TWITTER_CONSUMER_SECRET)
  end

  get '/api/auth/twitter' do
    # TODO: authentication_request_token
    request_token = @client.request_token(oauth_callback: "#{host_with_port}/api/auth/twitter/callback")
    session[:request_token] = request_token.token
    session[:request_token_secret] = request_token.secret

    redirect to(request_token.authorize_url)
  end

  get '/api/auth/twitter/callback' do
    access_token = @client.authorize(
      session[:request_token],
      session[:request_token_secret],
      oauth_verifier: params[:oauth_verifier])

    if @client.authorized?
      # Store/update this social service in database
      service = current_user.twitter_service
      if service
        service.update(
          access_token: access_token.token,
          access_token_secret: access_token.secret,
          active: true)
      else
        current_user.add_social_service(
          provider: 'twitter',
          access_token: access_token.token,
          access_token_secret: access_token.secret)
      end

      current_user.increment_active_workers!

      # Enqueue data grabber
      Resque.enqueue(TwitterGrabber, current_user.id, access_token.token, access_token.secret)

      slim :auth_twitter_callback
    else
      401
    end
  end

  get '/api/links' do
    return 403 unless service_ready?
    return json(status: 'wait') unless current_user.active_workers == 0

    # request links through recommender system interface
    links = fetch_links_for(current_user.id)
    if links
      json(status: 'done', links: links)
    else
      json(status: 'error')
    end
  end
end
