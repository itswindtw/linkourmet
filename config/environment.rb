RACK_ENV = ENV['RACK_ENV'] || 'development'
BASE_PATH = File.expand_path('../..', __FILE__)

require 'bundler/setup'
Bundler.require(:default, RACK_ENV)

puts "Initializing App in #{RACK_ENV} mode..."
