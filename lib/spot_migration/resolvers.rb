# frozen_string_literal: true

module SpotMigration
  module Resolvers
    Bitstream = Struct.new(:name, :io)

    require_relative 'resolvers/file_system'
    require_relative 'resolvers/ldr'
  end
end
