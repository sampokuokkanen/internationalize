# frozen_string_literal: true

module Internationalize
  module Adapters
    # Base adapter class defining the interface for database-specific SQL generation
    class Base
      # Sanitize a locale for safe SQL interpolation
      # Only allows alphanumeric characters, underscores, and hyphens
      #
      # @param locale [String, Symbol] the locale key
      # @return [String] sanitized locale safe for SQL interpolation
      def sanitize_locale(locale)
        locale.to_s.gsub(/[^a-zA-Z0-9_\-]/, "")
      end

      # Extract a value from a JSON column
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [String] SQL fragment for extracting the value
      def json_extract(column, locale)
        raise NotImplementedError, "#{self.class} must implement #json_extract"
      end

      # Generate a case-insensitive LIKE condition
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [Array<String, Symbol>] SQL fragment and pattern type
      def like_insensitive(column, locale)
        raise NotImplementedError, "#{self.class} must implement #like_insensitive"
      end

      # Generate a case-sensitive LIKE/GLOB condition
      #
      # @param column [String] the JSON column name
      # @param locale [String, Symbol] the locale key
      # @return [Array<String, Symbol>] SQL fragment and pattern type
      def like_sensitive(column, locale)
        raise NotImplementedError, "#{self.class} must implement #like_sensitive"
      end

      # Wrap a LIKE pattern with wildcards
      # Uses ActiveRecord's built-in sanitize_sql_like for escaping
      #
      # @param term [String] the search term
      # @return [String] pattern with wildcards
      def like_pattern(term)
        "%#{ActiveRecord::Base.sanitize_sql_like(term.to_s)}%"
      end

      # Wrap a term with pattern wildcards for case-sensitive search
      # Default implementation uses LIKE pattern (PostgreSQL/MySQL)
      # SQLite overrides this to use GLOB pattern
      #
      # @param term [String] the search term
      # @return [String] pattern with wildcards
      def glob_pattern(term)
        like_pattern(term)
      end
    end
  end
end
