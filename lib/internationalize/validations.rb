# frozen_string_literal: true

module Internationalize
  # Validation support for internationalized attributes
  #
  # For simple validations (presence, length, format), use standard Rails validations
  # which work with the virtual accessor for the current locale:
  #
  #   validates :title, presence: true
  #   validates :title, length: { minimum: 3 }
  #
  # Use validates_international for:
  # - Uniqueness (requires JSON column querying)
  # - Multi-locale presence (admin interfaces editing all translations at once)
  #
  # @example Uniqueness per-locale
  #   validates_international :title, uniqueness: true
  #
  # @example Require specific locales (admin/manager interfaces)
  #   validates_international :title, presence: { locales: [:en, :de] }
  #
  module Validations
    extend ActiveSupport::Concern

    class_methods do
      # Validates internationalized attributes
      #
      # @param attrs [Array<Symbol>] attribute names to validate
      # @param options [Hash] validation options
      # @option options [Boolean] :uniqueness validate uniqueness per-locale (current locale)
      # @option options [Hash] :presence with :locales array for multi-locale presence
      #
      # @example Uniqueness validation (per-locale)
      #   validates_international :title, uniqueness: true
      #
      # @example Multi-locale presence (for admin interfaces)
      #   validates_international :title, presence: { locales: [:en, :de] }
      #
      def validates_international(*attrs, **options)
        presence_opts = options.delete(:presence)
        uniqueness_opts = options.delete(:uniqueness)

        attrs.each do |attr|
          validate_international_presence(attr, presence_opts) if presence_opts
          validate_international_uniqueness(attr, uniqueness_opts) if uniqueness_opts
        end
      end

      private

      def validate_international_presence(attr, options)
        unless options.is_a?(Hash) && options[:locales]
          raise ArgumentError, "validates_international presence requires locales: option. " \
            "For current locale, use: validates :#{attr}, presence: true"
        end

        locales = options[:locales].map(&:to_s)

        validate do |record|
          locales.each do |locale|
            value = record.send("#{attr}_#{locale}")
            if value.blank?
              record.errors.add(attr, :blank)
            end
          end
        end
      end

      def validate_international_uniqueness(attr, _options)
        validate do |record|
          locale = I18n.locale.to_s
          value = record.send("#{attr}_#{locale}")
          next if value.blank?

          scope = record.class.international(attr => value, locale: locale)
          scope = scope.where.not(id: record.id) if record.persisted?

          if scope.exists?
            record.errors.add(attr, :taken)
          end
        end
      end
    end
  end
end
