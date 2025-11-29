# frozen_string_literal: true

require_relative "adapters/base"
require_relative "adapters/sqlite"
require_relative "adapters/postgresql"
require_relative "adapters/mysql"

module Internationalize
  module Adapters
    class << self
      # Returns the appropriate SQL generator for the current database
      # Detection is based on ActiveRecord's connection adapter name
      #
      # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter]
      # @return [Internationalize::Adapters::Base] the SQL generator
      def resolve(connection = ActiveRecord::Base.connection)
        case connection.adapter_name.downcase
        when /sqlite/
          SQLite.new
        when /postgres/
          PostgreSQL.new
        when /mysql|trilogy/
          MySQL.new
        else
          raise UnsupportedAdapter, "Database adapter '#{connection.adapter_name}' is not supported. " \
            "Supported adapters: sqlite, postgresql, mysql"
        end
      end
    end

    # Raised when an unsupported database adapter is detected
    class UnsupportedAdapter < StandardError; end
  end
end
