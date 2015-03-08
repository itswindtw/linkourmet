# Load App Path
$:.unshift(File.join(BASE_PATH, 'app'))
$:.unshift(File.join(BASE_PATH, 'config'))

# Database
require 'sequel'
require 'yaml'
db_config = YAML.load_file(File.join(BASE_PATH, 'config/database.yml'))[RACK_ENV]
DB = Sequel.connect(db_config)

Sequel.extension :migration
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Resque
require 'resque'

# Logging
# env['rack.logger']
