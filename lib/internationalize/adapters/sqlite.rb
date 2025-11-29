# frozen_string_literal: true

require_relative "base"

module Internationalize
  module Adapters
    # SQLite-specific SQL generation for JSON queries
    #
    # Uses json_extract() function (SQLite 3.38+)
    # LIKE for case-insensitive matching (default for ASCII)
    # GLOB for case-sensitive matching
    class SQLite < Base
      # Extract a value from a JSON column using json_extract
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [String] SQL fragment
      def json_extract(column, locale)
        "json_extract(#{column}, '$.#{sanitize_locale(locale)}')"
      end

      # Case-insensitive search using LIKE (default for ASCII in SQLite)
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_insensitive(column, locale)
        ["#{json_extract(column, locale)} LIKE ? ESCAPE '\\'", :like]
      end

      # Case-sensitive search using GLOB
      #
      # @return [Array<String, Symbol>] SQL condition and pattern type
      def like_sensitive(column, locale)
        ["#{json_extract(column, locale)} GLOB ?", :glob]
      end

      # GLOB pattern with wildcards
      # GLOB uses * and ? instead of % and _, and is case-sensitive
      #
      # @param term [String] the search term
      # @return [String] GLOB pattern with wildcards
      def glob_pattern(term)
        # Escape GLOB special characters: * ? [ ]
        escaped = term.to_s.gsub(/[*?\[\]]/) { |m| "[#{m}]" }
        "*#{escaped}*"
      end
    end
  end
end
