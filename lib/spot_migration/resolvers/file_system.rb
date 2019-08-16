# frozen_string_literal: true
module SpotMigration
  module Resolvers
    class FileSystem
      attr_reader :asset_base, :extension

      def initialize(asset_base, extension: nil)
        @asset_base = asset_base
        @extension = extension
      end

      def call(id, _csv_row)
        File.join(asset_base, id + extension)
      end
    end

    class Newspaper < FileSystem
      def call(_id, csv_row)
        date = Array(row['dc:date']).first
        parsed_date = DateTime.parse(date).strftime('%Y_%m_%d')
        File.join(asset_base, "lafayette_newspaper_#{parsed_date}_OBJ.pdf")
      end
    end
  end
end
