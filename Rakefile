require 'yaml'
require 'sequel'

namespace :db do
  task :environment do
    DATABASE_ENV = ENV['DATABASE_ENV'] || 'development'
    MIGRATIONS_DIR = ENV['MIGRATIONS_DIR'] || 'db/migrations'
  end

  task configuration: :environment do
    config_path = File.expand_path('config/database.yml', File.dirname(__FILE__))
    @config = YAML.load_file(config_path)[DATABASE_ENV]
  end

  task establish_connection: :configuration do
    DB = Sequel.connect(@config)
    Sequel.extension :migration
  end

  task drop: :establish_connection do
    Sequel::Migrator.run(DB, MIGRATIONS_DIR, target: 0)
  end

  task migrate: :establish_connection do
    if Sequel::Migrator.is_current?(DB, MIGRATIONS_DIR)
      puts 'No need to do migration.'
    else
      Sequel::Migrator.run(DB, MIGRATIONS_DIR)
      Rake::Task['db:schema:dump'].invoke
    end
  end

  namespace :schema do
    task dump: :establish_connection do
      DB.extension :schema_dumper
      File.open('db/schema.rb', 'w') do |f|
        f << DB.dump_schema_migration
      end
    end
  end
end
