# frozen_string_literal: true

require_relative "base"

module Internationalize
  module Adapters
    # PostgreSQL-specific SQL generation for JSON/JSONB queries
    #
    # Uses ->> operator for text extraction from JSON/JSONB columns
    # ILIKE for case-insensitive matching
    # LIKE for case-sensitive matching
    class PostgreSQL < Base
      # Extract a value from a JSON/JSONB column using ->> operator
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [String] SQL fragment
      def json_extract(column, locale)
        "#{column}->>'#{sanitize_locale(locale)}'"
      end

      # Case-insensitive search using ILIKE
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_insensitive(column, locale)
        ["#{json_extract(column, locale)} ILIKE ?", :like]
      end

      # Case-sensitive search using LIKE
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_sensitive(column, locale)
        ["#{json_extract(column, locale)} LIKE ?", :like]
      end
    end
  end
end
