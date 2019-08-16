# frozen_string_literal: true

require 'bagit'
require 'csv'

# A service to generate a BagIt directory with some Lafayette boilerplate.

module SpotMigration
  class BagService
    attr_reader :id, :metadata, :files

    MULTI_VALUE_CHARACTER = '|'.freeze

    # @param [String] id
    # @param [Hash<* => *>] metadata
    # @param [Array<String, Pathname, (#io, #name)>] files
    #   When a String or Pathname, it is expected to be a full path
    #   to be copied to the bag.
    def initialize(id:, metadata:, files: [])
      @id = id
      @metadata = metadata
      @files = files
    end

    # Creates a directory at +#{destination}/#{id}+ and
    # writes the bag out there. Yields the Bag before
    # generating the manifest if you need to add files
    # or metadata, etc.
    #
    # @param [String, Pathname] destination
    # @return [BagIt::Bag]
    # @yieldparam [BagIt::Bag] bag
    def create!(destination:)
      destination = File.join(destination, sanitize_id(id))
      FileUtils.mkdir_p(destination)

      @bag = BagIt::Bag.new(destination, bag_info)

      add_metadata_to_bag
      add_files_to_bag

      yield @bag if block_given?

      @bag.manifest!(algo: 'sha256')

      @bag
    end

    private

    # @todo read this from a yaml file?
    # @return [Hash<String => String>]
    def bag_info
      {
        'Source-Organization' => 'Skillman Library, Lafayette College',
        'Bagging-Date' => bagging_date,
        'External-Identifier' => id
      }
    end

    # Parses the +:metadata+ passed to {#initialize} into the
    # +<bag_root>/data/metadata.csv+ file
    #
    # @return [void]
    def add_metadata_to_bag
      return if metadata.empty?

      @bag.add_file('metadata.csv') do |io|
        csv = CSV.new(io)
        csv << metadata.keys
        csv << metadata.values.map { |v| Array(v).join(MULTI_VALUE_CHARACTER) }
      end
    end

    # Copies the provided files to the bag.
    #
    # @return [void]
    def add_files_to_bag
      files.each do |file|
        return add_file_by_path(file) if file.is_a? String

        if file.respond_to?(:io) && file.respond_to?(:name)
          add_file_by_bitstream(file)
        end
      end
    end

    # When +@files+ is an array of Strings or Pathnames, we'll use
    # +BagIt::Bag#add_file(bag_path, file_path)+ to add the file
    #
    # @param [String, Pathname] file_path
    # @return [void]
    def add_file_by_path(file_path)
      basename = File.basename(file_path)
      bag_path = determine_bag_path(basename)
      @bag.add_file(bag_path, file_path)
    end

    # When +@files+ is an array of Bitstreams, we'll copy the +:io+ property
    # to the IO object generated from +BagIt::Bag#add_file(bag_path, &block)
    #
    # @param [#io, #name] stream
    # @return [void]
    def add_file_by_bitstream(stream)
      return unless stream.io && stream.name

      bag_name = determine_bag_path(stream.name)
      @bag.add_file(bag_name) do |bag_io|
        IO.copy_stream(stream.io, bag_io)
      end

      stream.io.close
    end

    # We might encounter a file that we don't want to store in +files/+
    # (ex. 'license.txt' file or other metadata), so we'll use
    # {#root_level_files} to determine what lives at the root of +data/+
    # and what lives in +files/+
    #
    # @param [String] name
    # @return [String]
    def determine_bag_path(name)
      name = sanitize_id(name)
      return name if root_level_files.include?(name)
      File.join('files', name)
    end

    # Very long story short, we can't have '+' characters in our ids, so we'll
    # strip them out
    #
    # @return [String]
    def sanitize_id(str)
      str.gsub(/\+|\s+|\:/, '_')
    end

    # @return [Array<String>]
    def root_level_files
      %w[license.txt metadata.csv]
    end

    # @return [String] Today's date in YYYY-MM-DD format
    def bagging_date
      Time.now.strftime('%Y-%m-%d')
    end
  end
end
