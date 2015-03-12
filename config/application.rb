# Migrations
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Resque
require 'resque'

# Logging
# env['rack.logger']
