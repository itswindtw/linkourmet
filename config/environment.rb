RACK_ENV = ENV['RACK_ENV'] || 'development'
BASE_PATH = File.expand_path('../..', __FILE__)

require 'bundler'
Bundler.setup(:default, RACK_ENV)

puts "Initializing App in #{RACK_ENV} mode..."
