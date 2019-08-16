require 'pg'
require 'date'

namespace :create_bags do
  task :ldr do
    user = ENV['db_user']
    pass = ENV['db_pass']
    host = ENV['db_host']
    csv_path = ENV['csv_path']
    asset_base = ENV['asset_base']
    output = ENV['output']

    raise 'Need to set "db_user", "db_pass" and "db_host" variables!' unless user && pass && host
    raise 'Need to provide a path to a CSV file via "csv_path"' unless csv_path && File.exist?(csv_path)
    raise 'Need to provide a path to an asset base via "asset_base' unless asset_base && File.directory?(asset_base)
    raise 'Need to provide an output path via "output"' unless output && File.directory?(output)

    pg = PG.connect(user: user, password: pass, host: host, dbname: 'dspace')

    resolver = SpotMigration::Resolvers::Ldr.new(db_adapter: pg, asset_store_base: asset_base)
    factory = SpotMigration::BagFactory.new(file_resolver: resolver, csv_path: csv_path)
    factory.run(destination: output, zip: true)
  end

  task :magazine do
    csv_path = ENV['csv_path']
    asset_base = ENV['asset_base']
    output = ENV['output']

    resolver = SpotMigration::Resolvers::FileSystem.new(asset_base, extension: '.pdf')
    factory = SpotMigration::BagFactory.new(file_resolver: resolver, csv_path: csv_path, id_key: 'File')
    factory.run(destination: output, zip: true)
  end

  task :newspaper do
    csv_path = ENV['csv_path']
    asset_base = ENV['asset_base']
    output = ENV['output']

    resolver = SpotMigration::Resolvers::Newspaper.new(asset_base)
    factory = SpotMigration::BagFactory.new(file_resolver: resolver, csv_path: csv_path)
    factory.run(destination: output, zip: true)
  end

  task :shakespeare do
    csv_path = ENV['csv_path']
    asset_base = ENV['asset_base']
    output = ENV['output']

    resolver = SpotMigration::Resolvers::FileSystem.new(asset_base, extension: '.pdf')
    factory = SpotMigration::BagFactory.new(file_resolver: resolver, csv_path: csv_path, id_key: 'File')
    factory.run(destination: output, zip: true)
  end
end
