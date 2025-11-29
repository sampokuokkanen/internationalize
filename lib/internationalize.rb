# frozen_string_literal: true

require "active_support"
require "active_record"

require_relative "internationalize/version"
require_relative "internationalize/adapters"
require_relative "internationalize/model"

module Internationalize
  class << self
    # Configuration
    attr_accessor :available_locales

    def configure
      yield self
    end

    # Returns available locales, defaulting to I18n.available_locales
    def locales
      available_locales || I18n.available_locales
    end
  end

  class Railtie < Rails::Railtie
    initializer "internationalize.action_text" do
      ActiveSupport.on_load(:action_text_rich_text) do
        require "internationalize/rich_text"
      end
    end
  end if defined?(Rails::Railtie)
end
