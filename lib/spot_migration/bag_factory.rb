# frozen_string_literal: true

# Like a literal factory for spitting out BagIt directories from a CSV file
# and a directory of files. Cue Raymond Scott.
#
# @example Generate bags from a csv file
#   csv_path = '/path/to/all-the-items.csv'
#   file_source = 'a'
#   factory = SpotMigration::BagFactory.new(csv_path: csv_path,
#                                           file_source: source)
require 'fileutils'

module SpotMigration
  class BagFactory
    # @param [String, Pathname] csv_path
    # @param [#call] file_resolver
    def initialize(csv_path:, file_resolver:, id_key: 'id')
      @csv_path = csv_path
      @file_resolver = file_resolver
      @id_key = id_key
    end

    # @param [String, Pathname] destination
    # @return [void]
    def run(destination:, zip: false)
      parsed_csv do |row|
        id = Array(row.delete(@id_key)).first
        files = Array(@file_resolver.call(id, row))

        puts "creating: #{id}"

        bag = BagService.new(id: id, metadata: row, files: files)
                  .create!(destination: destination)

        next unless zip

        ZipService.new(src_path: bag.bag_dir).zip!(dest_path: "#{bag.bag_dir}.zip")
        FileUtils.remove_entry(bag.bag_dir)
      end
    end

    private

    # @yield [Hash<String => Array<String>>]
    def parsed_csv
      split = ->(v) { v.split(split_character) }
      CSV.foreach(@csv_path, headers: true, converters: split) do |row|
        next unless row[@id_key]
        yield row.to_h
      end
    end

    # @return [String]
    def split_character
      BagService::MULTI_VALUE_SEPARATOR
    end
  end
end
