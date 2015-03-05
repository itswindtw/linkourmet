require 'sinatra/base'

class Solid < Sinatra::Base
  get '/' do
    'Hello world'
  end
end
