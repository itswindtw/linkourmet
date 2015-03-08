# Database
require 'sequel'
require 'yaml'
db_config = YAML.load_file(File.join(BASE_PATH, 'config/database.yml'))[RACK_ENV]
DB = Sequel.connect(db_config)

Sequel.extension :migration
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Logging
# env['rack.logger']

# Sinatra App
require_relative File.join(BASE_PATH, 'app')
