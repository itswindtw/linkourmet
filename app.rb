require 'sinatra/base'

class Solid < Sinatra::Base
  configure :production, :development do
    enable :logging
  end

  get '/' do
    slim :init
  end
end
