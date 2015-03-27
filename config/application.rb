# Migrations
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Models
require 'models'

# Resque
require 'resque'

Resque.before_fork do
  defined?(DB) && DB.disconnect
end

# Logging
# env['rack.logger']
