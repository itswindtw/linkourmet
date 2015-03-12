# Migrations
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Models
require 'models'

# Resque
require 'resque'

# Logging
# env['rack.logger']
