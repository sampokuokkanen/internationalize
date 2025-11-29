# frozen_string_literal: true

# Try to use the main test helper if available (when running all tests together)
# Otherwise set up our own environment (when running integration tests alone)
if File.exist?(File.expand_path("../test_helper.rb", __dir__))
  require_relative "../test_helper"
else
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch
  end

  require "active_record"
  require "active_support"
  require "active_support/test_case"
  require "minitest/autorun"
  require "i18n"
  require "internationalize"

  I18n.available_locales = [:en, :de, :fr, :es]
  I18n.default_locale = :en

  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:",
  )

  ActiveRecord::Schema.define do
    create_table :blogs, force: true do |t|
      t.json(:title_translations, default: {})
      t.json(:body_translations, default: {})
      t.string(:author)
      t.boolean(:published, default: false)
      t.timestamps
    end
  end

  class Blog < ActiveRecord::Base
    include Internationalize::Model

    international :title, :body
  end
end

class IntegrationTestCase < ActiveSupport::TestCase
  def setup
    I18n.locale = :en
    Blog.delete_all if defined?(Blog) && Blog.table_exists?
  end
end
