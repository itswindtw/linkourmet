require 'sinatra/base'

class Solid < Sinatra::Base
  get '/' do
    slim :init
  end
end
