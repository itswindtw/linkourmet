require 'sinatra/base'
require 'sinatra/reloader'
require 'koala'

require 'solid_secret'
require_relative 'link_grabber'

class Solid < Sinatra::Base
  configure do
    enable :logging
    enable :sessions

    set :session_secret, SolidSecret::SESSION_SECRET

    register Sinatra::Reloader if development?
  end

  #

  get '/' do
    slim :index
  end

  get '/links' do
    # TODO
  end

  get '/error' do
    # TODO
  end

  #

  post '/api/auth' do
    user_id = params[:userID].to_s
    access_token = params[:accessToken].to_s

    graph = Koala::Facebook::API.new(access_token)

    # revalidate user_id and token, if not, return 400
    profile = graph.get_object('me')
    return 400 if profile['id'] != user_id

    # login here
    session[:user_id] = user_id

    # stores user_id, token to database
    users = DB[:users]
    this_user = users.where(user_id: user_id)
    unless this_user.update(access_token: access_token) == 1
      users.insert(user_id: user_id, access_token: access_token)
    end

    # TODO: enqueue a request to data grabber
    200
  end

  get '/api/links' do
    # fetch user_id, if not found, return 403

    # check whether resque is done
    # request links through recommender system interface
  end

end
