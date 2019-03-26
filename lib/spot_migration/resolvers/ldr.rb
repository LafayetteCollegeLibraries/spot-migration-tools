# frozen_string_literal: true

# A Bitstream resolver for our legacy DSpace installation.
module SpotMigration
  module Resolvers
    class Ldr
      # @param [#exec] db_adapter
      # @param [String, Pathname] asset_store_base
      def initialize(db_adapter:, asset_store_base:)
        @db = db_adapter
        @asset_store_base = asset_store_base
      end

      # @param [String] id
      # @param [Hash<String => Array<String>>] _row_metadata Not used
      # @return [Array<SpotMigration::Resolvers::Bitstream>]
      def call(id, _row_metadata = nil)
        @db.exec(bitstream_query, [id])
           .reject { |result| result['bitstream_description'] == 'Extracted text' }
           .map { |results| bitstream_from_results(results) }
      end

      private

      # The SQL query used to fetch info about
      #
      # @return [String]
      def bitstream_query
        <<-SQL
          SELECT
            bitstream.name,
            bitstream.bitstream_format_id,
            bitstream.checksum,
            bitstream.description as bitstream_description,
            bitstream.internal_id,
            format.mimetype,
            format.short_description,
            format.description FROM item2bundle AS i2b
          INNER JOIN bundle ON bundle.bundle_id=i2b.bundle_id
          LEFT JOIN bundle2bitstream AS b2b ON b2b.bundle_id=bundle.bundle_id
          INNER JOIN bitstream ON bitstream.bitstream_id=b2b.bitstream_id
          INNER JOIN bitstreamformatregistry as format on bitstream.bitstream_format_id=format.bitstream_format_id
          WHERE i2b.item_id=$1
        SQL
      end

      def bitstream_from_results(results)
        io = File.open(path_from_id(results['internal_id']), 'r')
        Bitstream.new(results['name'], io)
      end

      def path_from_id(id)
        parts = [id[0..1], id[2..3], id[4..5], id]
        File.join(@asset_store_base, *parts)
      end
    end
  end
end
