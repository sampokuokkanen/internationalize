# frozen_string_literal: true

require_relative "base"

module Internationalize
  module Adapters
    # MySQL 8+ specific SQL generation for JSON queries
    #
    # Uses ->> operator for text extraction from JSON columns
    # LIKE for case-insensitive matching (default with utf8mb4 collation)
    # LIKE BINARY for case-sensitive matching
    class MySQL < Base
      # Extract a value from a JSON column using ->> operator
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [String] SQL fragment
      def json_extract(column, locale)
        "#{column}->>'$.#{sanitize_locale(locale)}'"
      end

      # Case-insensitive search using LIKE (default behavior with utf8mb4)
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_insensitive(column, locale)
        ["#{json_extract(column, locale)} LIKE ?", :like]
      end

      # Case-sensitive search using LIKE BINARY
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_sensitive(column, locale)
        ["#{json_extract(column, locale)} LIKE BINARY ?", :like]
      end
    end
  end
end
