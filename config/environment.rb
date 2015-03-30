RACK_ENV = ENV['RACK_ENV'] || 'development'
BASE_PATH = File.expand_path('../..', __FILE__)

require 'bundler'
Bundler.setup(:default, RACK_ENV)

puts "Initializing App in #{RACK_ENV} mode..."

# Load App Path
$LOAD_PATH.unshift(File.join(BASE_PATH, 'app'))
$LOAD_PATH.unshift(File.join(BASE_PATH, 'config'))

# Database connection
require 'sequel'
require 'yaml'

db_config = if RACK_ENV == 'production'
  ENV['DATABASE_URL']
else
  YAML.load_file(File.join(BASE_PATH, 'config/database.yml'))[RACK_ENV]
end
DB = Sequel.connect(db_config)
Sequel.extension :migration
