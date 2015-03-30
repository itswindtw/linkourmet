# Migrations
Sequel::Migrator.check_current(DB, File.join(BASE_PATH, 'db/migrations'))

# Models
require 'models'

# Redis
require 'redis'
if ENV['REDISCLOUD_URL']
  uri = URI.parse(ENV["REDISCLOUD_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

# Resque
require 'resque'

Resque.before_fork do
  defined?(DB) && DB.disconnect
end

API_ENDPOINT = 'http://linkrec.ddns.net:3000'

# Logging
# env['rack.logger']
