# Sinatra
require 'sinatra/base'
require 'sinatra/reloader'
require 'slim'

# bcrypt
require 'bcrypt'

# Facebook graph API
require 'koala'

# Solid
require 'facebook_grabber'
require 'solid_secret'

class Solid < Sinatra::Base
  configure do
    enable :logging
    enable :sessions

    set :root, BASE_PATH
    set :session_secret, SolidSecret::SESSION_SECRET

    register Sinatra::Reloader if development?
  end

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
  end

  #
  get '/' do
    return redirect to('/auth') unless logged_in?

    @social_services = current_user.social_services.map(&:provider)
    slim :index
  end

  get '/links' do
    return redirect to('/') unless logged_in? and current_user.social_services.length > 0

    slim :links
  end

  get '/auth' do
    return redirect to('/') if logged_in?

    @user = User.new
    slim :auth
  end

  post '/signin' do
    @user = User.where(email: params[:inputEmail]).first

    if @user and BCrypt::Password.new(@user.password) == params[:inputPassword]
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
      current_user.add_social_service(provider: 'facebook', access_token: access_token)
    end

    # Enqueue data grabber
    Resque.enqueue(FacebookGrabber, access_token)

    201
  end

  delete '/api/auth/facebook' do
    service = current_user.facebook_service
    service.update(active: false) if service

    200
  end

  post '/api/auth/twitter' do
    # TODO
  end

  get '/api/links' do
    # TODO

    # fetch user_id, if not found, return 403

    # check whether resque is done
    # request links through recommender system interface
  end
end
