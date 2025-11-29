# frozen_string_literal: true

module Internationalize
  # Adds internationalization support for ActionText rich text attributes
  #
  # @example
  #   class Article < ApplicationRecord
  #     include Internationalize::Model
  #     include Internationalize::RichText
  #     international_rich_text :content
  #   end
  #
  #   article.content = "<p>Hello</p>"  # Sets for current locale
  #   article.content                    # Gets for current locale (with fallback)
  #   article.content_de                 # Direct access to German content
  #
  module RichText
    extend ActiveSupport::Concern

    class_methods do
      # Declares a rich text attribute as internationalized
      #
      # Creates a has_rich_text association for each available locale and
      # provides locale-aware accessors.
      #
      # @param name [Symbol] the attribute name
      #
      def international_rich_text(name)
        # Validate locales don't contain hyphens (invalid for Ruby method names)
        Internationalize.locales.each do |locale|
          locale_str = locale.to_s
          if locale_str.include?("-")
            raise ArgumentError, "Locale '#{locale}' contains a hyphen which is invalid for Ruby method names. " \
              "Use underscore format instead: :#{locale_str.tr('-', '_')}"
          end
        end

        # Generate has_rich_text for each locale
        Internationalize.locales.each do |locale|
          rich_text_name = :"#{name}_#{locale}"
          has_rich_text(rich_text_name)
        end

        default_locale_str = I18n.default_locale.to_s

        # Main getter - returns rich text for current locale with fallback to default locale
        define_method(name) do
          locale_str = I18n.locale.to_s
          rich_text = send(:"#{name}_#{locale_str}")

          if rich_text.blank? && locale_str != default_locale_str
            send(:"#{name}_#{default_locale_str}")
          else
            rich_text
          end
        end

        # Main setter - sets rich text for current locale
        define_method(:"#{name}=") do |value|
          send(:"#{name}_#{I18n.locale}=", value)
        end

        # Predicate method
        define_method(:"#{name}?") do
          send(name).present?
        end

        # Check if translation exists for a specific locale
        define_method(:"#{name}_translated?") do |locale|
          send(:"#{name}_#{locale}").present?
        end

        # Get all locales that have this rich text
        define_method(:"#{name}_translated_locales") do
          Internationalize.locales.select do |locale|
            send(:"#{name}_#{locale}").present?
          end
        end
      end
    end
  end
end
