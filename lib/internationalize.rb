# frozen_string_literal: true

require "active_support"
require "active_record"

require_relative "internationalize/version"
require_relative "internationalize/adapters"
require_relative "internationalize/model"

module Internationalize
  class << self
    # Configuration
    attr_accessor :fallback_locale, :available_locales

    def configure
      yield self
    end

    # Returns the current locale, defaulting to I18n.locale
    def locale
      I18n.locale
    end

    # Returns the default locale for fallbacks
    def default_locale
      fallback_locale || I18n.default_locale
    end

    # Returns available locales, defaulting to I18n.available_locales
    def locales
      available_locales || I18n.available_locales
    end
  end
end
