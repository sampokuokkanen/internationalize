# frozen_string_literal: true

require "test_helper"
require "internationalize/rich_text"

# Minimal stub for ActionText::Attribute
# This allows us to test international_rich_text without full Rails/ActionText stack
module ActionText
  module Attribute
    extend ActiveSupport::Concern

    class_methods do
      def has_rich_text(name)
        # Create simple getter/setter that stores in instance variable
        define_method(name) do
          instance_variable_get("@#{name}")
        end

        define_method("#{name}=") do |value|
          instance_variable_set("@#{name}", value)
        end
      end
    end
  end
end

class RichTextHyphenatedLocaleTest < Minitest::Test
  def setup
    @original_locale = I18n.locale
    @original_available_locales = I18n.available_locales
    @original_internationalize_locales = Internationalize.available_locales
  end

  def teardown
    # Restore in reverse order: first restore available_locales, then locale
    # This prevents I18n::InvalidLocale errors
    Internationalize.available_locales = @original_internationalize_locales
    I18n.available_locales = @original_available_locales
    I18n.locale = @original_locale
  end

  # Issue: https://github.com/sampokuokkanen/internationalize/issues/10
  #
  # When I18n.locale returns a hyphenated string like "zh-TW" at runtime
  # (which some gems like gettext_i18n_rails do), the international_rich_text
  # getter tries to call :body_zh-TW instead of :body_zh_TW, causing NoMethodError.
  #
  # The methods are defined with underscores (body_zh_TW) but the locale string
  # at runtime may contain hyphens (zh-TW).

  def test_getter_normalizes_hyphenated_locale_at_runtime
    # Add hyphenated locale to available_locales (simulates gettext_i18n_rails behavior)
    I18n.available_locales = [:en, :zh_TW, :"zh-TW"]
    Internationalize.available_locales = [:en, :zh_TW]

    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "articles"

      include ActionText::Attribute
      include Internationalize::Model
      include Internationalize::RichText

      international_rich_text :body
    end

    instance = model_class.new
    instance.body_zh_TW = "Traditional Chinese content"

    # Set hyphenated locale directly (simulates gettext_i18n_rails behavior)
    I18n.locale = :"zh-TW"
    # BUG: This raises NoMethodError because it tries to call :body_zh-TW
    # FIX: Should normalize "zh-TW" to "zh_TW" before calling send()
    assert_equal("Traditional Chinese content", instance.body)
  end

  def test_setter_normalizes_hyphenated_locale_at_runtime
    # Add hyphenated locale to available_locales (simulates gettext_i18n_rails behavior)
    I18n.available_locales = [:en, :zh_TW, :"zh-TW"]
    Internationalize.available_locales = [:en, :zh_TW]

    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "articles"

      include ActionText::Attribute
      include Internationalize::Model
      include Internationalize::RichText

      international_rich_text :body
    end

    instance = model_class.new

    # Set hyphenated locale directly (simulates gettext_i18n_rails behavior)
    I18n.locale = :"zh-TW"
    # BUG: This raises NoMethodError because it tries to call :body_zh-TW=
    # FIX: Should normalize "zh-TW" to "zh_TW" before calling send()
    instance.body = "Traditional Chinese content"

    assert_equal("Traditional Chinese content", instance.body_zh_TW)
  end

  def test_fallback_normalizes_hyphenated_locale
    # Add hyphenated locale to available_locales (simulates gettext_i18n_rails behavior)
    I18n.available_locales = [:en, :zh_TW, :"zh-TW"]
    Internationalize.available_locales = [:en, :zh_TW]
    original_default = I18n.default_locale
    I18n.default_locale = :en

    model_class = Class.new(ActiveRecord::Base) do
      self.table_name = "articles"

      include ActionText::Attribute
      include Internationalize::Model
      include Internationalize::RichText

      international_rich_text :body
    end

    instance = model_class.new
    instance.body_en = "English fallback content"
    # zh_TW has no content, should fallback to en

    # Set hyphenated locale directly (simulates gettext_i18n_rails behavior)
    I18n.locale = :"zh-TW"
    # Should fallback to default locale (en) when zh_TW has no content
    assert_equal("English fallback content", instance.body)
  ensure
    I18n.default_locale = original_default
  end
end
