# frozen_string_literal: true

require "rails"
require "active_record/railtie"

# Require internationalize
require "internationalize"

module Dummy
  class Application < Rails::Application
    config.load_defaults(Rails::VERSION::STRING.to_f)
    config.eager_load = false

    # Don't generate system test files
    config.generators.system_tests = nil
  end
end
