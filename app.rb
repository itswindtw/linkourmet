require 'sinatra/base'
require 'sinatra/reloader'

class Solid < Sinatra::Base
  configure do
    enable :logging

    register Sinatra::Reloader if development?
  end

  get '/' do
    slim :init
  end
end
