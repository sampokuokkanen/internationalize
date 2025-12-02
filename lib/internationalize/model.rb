# frozen_string_literal: true

require_relative "validations"

module Internationalize
  # Mixin for ActiveRecord models to enable internationalization
  #
  # @example
  #   class Article < ApplicationRecord
  #     include Internationalize::Model
  #     international :title, :description
  #   end
  #
  #   # Querying
  #   Article.i18n_where(title: "Hello")
  #   Article.i18n_where(title: "hello", match: :partial)
  #   Article.international_order(:title, :desc)
  #
  module Model
    extend ActiveSupport::Concern
    include Internationalize::Validations

    VALID_DIRECTIONS = ["ASC", "DESC"].freeze

    included do
      class_attribute :international_attributes, default: []
    end

    class_methods do
      # Declares attributes as internationalized
      #
      # @example
      #   international :title, :description
      #
      # @param attributes [Array<Symbol>] attributes to declare as internationalized
      #
      # @deprecated Using this method for querying is deprecated.
      #   Use {#i18n_where} or {#international_where} instead.
      #
      def international(*attributes, locale: nil, match: :exact, case_sensitive: false, **conditions)
        if attributes.any? && attributes.first.is_a?(Symbol) && conditions.empty?
          # Declaration mode: international :title, :description
          declare_international_attributes(attributes)
        else
          # Query mode: Article.international(title: "Hello") - DEPRECATED
          warn("[Internationalize] DEPRECATION WARNING: Using `international` for querying is deprecated. " \
            "Use `i18n_where` or `international_where` instead. " \
            "(called from #{caller(1..1).first})")
          international_query(conditions, locale: locale, match: match, case_sensitive: case_sensitive)
        end
      end

      # Query translated attributes
      #
      # @param conditions [Hash] attribute => value pairs to query
      # @param locale [Symbol] locale to query (default: current locale)
      # @param match [Symbol] :exact or :partial (default: :exact)
      # @param case_sensitive [Boolean] for partial matching only (default: false)
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   Article.international_where(title: "Hello")
      #   Article.international_where(title: "hello", match: :partial)
      #
      def international_where(locale: nil, match: :exact, case_sensitive: false, **conditions)
        international_query(conditions, locale: locale, match: match, case_sensitive: case_sensitive)
      end

      # Short alias for international_where
      #
      # @see #international_where
      #
      # @example
      #   Article.i18n_where(title: "Hello")
      #   Article.i18n_where(title: "hello", match: :partial)
      #
      def i18n_where(locale: nil, match: :exact, case_sensitive: false, **conditions)
        international_query(conditions, locale: locale, match: match, case_sensitive: case_sensitive)
      end

      # Order by translated attribute
      #
      # @param attribute [Symbol] attribute to order by
      # @param direction [Symbol] :asc or :desc (default: :asc)
      # @param locale [Symbol] locale to order by (default: current locale)
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   Article.international_order(:title)
      #   Article.international_order(:title, :desc)
      #   Article.international_order(:title, :desc, locale: :de)
      #
      def international_order(attribute, direction = :asc, locale: nil)
        unless international_attributes.include?(attribute.to_sym)
          raise ArgumentError, "#{attribute} is not an international attribute. " \
            "Use standard ActiveRecord methods for non-translated attributes."
        end

        locale ||= I18n.locale
        direction = direction.to_s.upcase
        direction = "ASC" unless VALID_DIRECTIONS.include?(direction)

        adapter = Adapters.resolve(connection)
        json_col = "#{attribute}_translations"
        order(Arel.sql("#{adapter.json_extract(json_col, locale)} #{direction}"))
      end

      # Find records that have a translation for the given attributes
      #
      # @param attributes [Array<Symbol>] attributes to check
      # @param locale [Symbol] locale to check (default: current locale)
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   Article.translated(:title)
      #   Article.translated(:title, :description, locale: :de)
      #
      def translated(*attributes, locale: nil)
        locale ||= I18n.locale
        adapter = Adapters.resolve(connection)
        scope = all

        attributes.each do |attr|
          next unless international_attributes.include?(attr.to_sym)

          json_col = "#{attr}_translations"
          extract = adapter.json_extract(json_col, locale)
          scope = scope.where("#{extract} IS NOT NULL AND #{extract} != ''")
        end

        scope
      end

      # Find records missing a translation for the given attributes
      #
      # @param attributes [Array<Symbol>] attributes to check
      # @param locale [Symbol] locale to check (default: current locale)
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   Article.untranslated(:title)
      #   Article.untranslated(:title, locale: :de)
      #
      def untranslated(*attributes, locale: nil)
        locale ||= I18n.locale
        adapter = Adapters.resolve(connection)
        scope = all

        attributes.each do |attr|
          next unless international_attributes.include?(attr.to_sym)

          json_col = "#{attr}_translations"
          extract = adapter.json_extract(json_col, locale)
          scope = scope.where("#{extract} IS NULL OR #{extract} = ''")
        end

        scope
      end

      # Exclude records matching translated attribute conditions
      #
      # @param conditions [Hash] attribute => value pairs to exclude
      # @param locale [Symbol] locale to use (default: current locale)
      # @return [ActiveRecord::Relation]
      #
      # @example
      #   Article.international_not(title: "Draft")
      #   Article.international_not(title: "Entwurf", locale: :de)
      #
      def international_not(locale: nil, **conditions)
        locale ||= I18n.locale
        adapter = Adapters.resolve(connection)
        scope = all

        conditions.each do |attr, value|
          unless international_attributes.include?(attr.to_sym)
            raise ArgumentError, "#{attr} is not an international attribute. " \
              "Use standard ActiveRecord methods for non-translated attributes."
          end

          json_col = "#{attr}_translations"
          extract = adapter.json_extract(json_col, locale)
          scope = scope.where("#{extract} != ? OR #{extract} IS NULL", value)
        end

        scope
      end

      # Create a new instance with translated attributes in a cleaner format
      #
      # @param attributes [Hash] attributes including translations as nested hashes
      # @return [ActiveRecord::Base] new unsaved instance
      #
      # @example
      #   Article.international_new(
      #     title: { en: "Hello", de: "Hallo" },
      #     status: "published"
      #   )
      #
      def international_new(attributes = {})
        new(convert_international_attributes(attributes))
      end

      # Create and save a record with translated attributes
      #
      # @param attributes [Hash] attributes including translations as nested hashes
      # @return [ActiveRecord::Base] the created record
      #
      # @example
      #   Article.international_create(title: { en: "Hello", de: "Hallo" })
      #
      def international_create(attributes = {})
        create(convert_international_attributes(attributes))
      end

      # Create and save a record with translated attributes, raising on failure
      #
      # @param attributes [Hash] attributes including translations as nested hashes
      # @return [ActiveRecord::Base] the created record
      # @raise [ActiveRecord::RecordInvalid] if validation fails
      #
      # @example
      #   Article.international_create!(title: { en: "Hello", de: "Hallo" })
      #
      def international_create!(attributes = {})
        create!(convert_international_attributes(attributes))
      end

      private

      # Convert international attributes from clean format to internal format
      #
      # { title: { en: "Hello", de: "Hallo" } }
      # becomes
      # { title_translations: { "en" => "Hello", "de" => "Hallo" } }
      #
      # Also supports direct assignment using current locale:
      # { title: "Achtung!" } with I18n.locale = :de
      # becomes
      # { title_translations: { "de" => "Achtung!" } }
      #
      def convert_international_attributes(attributes)
        result = {}

        attributes.each do |key, value|
          if international_attributes.include?(key.to_sym)
            result[:"#{key}_translations"] = if value.is_a?(Hash)
              value.transform_keys(&:to_s)
            else
              { I18n.locale.to_s => value }
            end
          else
            result[key] = value
          end
        end

        result
      end

      # Declares attributes as internationalized
      def declare_international_attributes(attributes)
        self.international_attributes = international_attributes | attributes.map(&:to_sym)

        attributes.each do |attr|
          warn_if_missing_default(attr)
          define_translation_accessors(attr)
          define_locale_accessors(attr)
        end
      end

      # Warn if JSON column is missing default: {}
      def warn_if_missing_default(attr)
        return unless table_exists?

        column = columns_hash["#{attr}_translations"]
        return unless column
        return if column.default.present?

        warn("[Internationalize] WARNING: Column #{table_name}.#{attr}_translations " \
          "is missing `default: {}`. This may cause errors. " \
          "Add `default: {}` to your migration.")
      end

      # Query translated attributes with exact or partial matching
      def international_query(conditions, locale:, match:, case_sensitive:)
        locale ||= I18n.locale
        adapter = Adapters.resolve(connection)
        scope = all

        conditions.each do |attr, value|
          unless international_attributes.include?(attr.to_sym)
            raise ArgumentError, "#{attr} is not an international attribute. " \
              "Use standard ActiveRecord methods for non-translated attributes."
          end

          json_col = "#{attr}_translations"

          scope = if match == :partial
            if case_sensitive
              sql, pattern_type = adapter.like_sensitive(json_col, locale)
              pattern = pattern_type == :glob ? adapter.glob_pattern(value) : adapter.like_pattern(value)
            else
              sql, _ = adapter.like_insensitive(json_col, locale)
              pattern = adapter.like_pattern(value)
            end
            scope.where(sql, pattern)
          else
            scope.where("#{adapter.json_extract(json_col, locale)} = ?", value)
          end
        end

        scope
      end

      # Defines the main getter/setter for an attribute
      def define_translation_accessors(attr)
        translations_column = "#{attr}_translations"

        # Main getter - returns translation for current locale with fallback to default locale
        default_locale_str = I18n.default_locale.to_s

        define_method(attr) do |locale = nil|
          locale_str = (locale || I18n.locale).to_s
          translations = read_attribute(translations_column)
          value = translations[locale_str]

          # Short-circuit: return early if value exists or already querying default locale
          return value if !value.nil? || locale_str == default_locale_str

          translations[default_locale_str]
        end

        # Main setter - sets translation for current locale
        define_method("#{attr}=") do |value|
          locale_str = I18n.locale.to_s
          translations = read_attribute(translations_column)
          translations[locale_str] = value
          write_attribute(translations_column, translations)
        end

        # Predicate method
        getter_method = attr.to_sym
        define_method("#{attr}?") do
          send(getter_method).present?
        end

        # Raw translations hash accessor
        define_method("#{attr}_translations") do
          read_attribute(translations_column)
        end

        # Set all translations at once
        define_method("#{attr}_translations=") do |hash|
          return write_attribute(translations_column, {}) if hash.nil?

          unless hash.is_a?(Hash)
            raise ArgumentError, "#{attr}_translations must be a Hash, got #{hash.class}"
          end

          allowed_locales = Internationalize.locales.map(&:to_s)
          hash.each_key do |key|
            unless allowed_locales.include?(key.to_s)
              raise ArgumentError, "Invalid locale '#{key}' for #{attr}_translations. " \
                "Allowed locales: #{allowed_locales.join(", ")}"
            end
          end

          write_attribute(translations_column, hash.stringify_keys)
        end
      end

      # Defines locale-specific accessors (title_en, title_de, etc.)
      def define_locale_accessors(attr)
        translations_column = "#{attr}_translations"

        Internationalize.locales.each do |locale|
          locale_str = locale.to_s

          if locale_str.include?("-")
            raise ArgumentError, "Locale '#{locale}' contains a hyphen which is invalid for Ruby method names. " \
              "Use underscore format instead: :#{locale_str.tr("-", "_")}"
          end

          getter_method = :"#{attr}_#{locale}"

          # Getter: article.title_en
          define_method(getter_method) do
            translations = read_attribute(translations_column)
            translations[locale_str]
          end

          # Setter: article.title_en = "Hello"
          define_method("#{attr}_#{locale}=") do |value|
            translations = read_attribute(translations_column)
            translations[locale_str] = value
            write_attribute(translations_column, translations)
          end

          # Predicate: article.title_en?
          define_method("#{attr}_#{locale}?") do
            send(getter_method).present?
          end
        end
      end
    end

    # Instance methods

    # Check if a translation exists for a specific locale
    def translated?(attr, locale)
      translations = read_attribute("#{attr}_translations")
      translations[locale.to_s].present?
    end

    # Returns all locales that have a translation for an attribute
    def translated_locales(attr)
      translations = read_attribute("#{attr}_translations")
      translations.filter_map { |k, v| k.to_sym if v.present? }
    end
  end
end
