# frozen_string_literal: true

require_relative "integration_test_helper"
require "rails/generators/test_case"
require "generators/internationalize/translation_generator"

class TranslationGeneratorTest < Rails::Generators::TestCase
  tests Internationalize::Generators::TranslationGenerator
  destination File.expand_path("../../tmp", __dir__)

  setup do
    prepare_destination
  end

  test "generates migration with single attribute" do
    run_generator ["Article", "title"]

    assert_migration "db/migrate/add_title_translations_to_articles.rb" do |migration|
      assert_match(/class AddTitleTranslationsToArticles/, migration)
      assert_match(/add_column :articles, :title_translations, :json, default: {}/, migration)
    end
  end

  test "generates migration with multiple attributes" do
    run_generator ["Post", "title", "body"]

    assert_migration "db/migrate/add_title_and_body_translations_to_posts.rb" do |migration|
      assert_match(/class AddTitleAndBodyTranslationsToPost/, migration)
      assert_match(/add_column :posts, :title_translations, :json, default: {}/, migration)
      assert_match(/add_column :posts, :body_translations, :json, default: {}/, migration)
    end
  end

  test "generates migration with namespaced model" do
    run_generator ["Admin::Article", "title", "description"]

    # Namespaced models use underscored table names (admin_articles)
    assert_migration "db/migrate/add_title_and_description_translations_to_admin_articles.rb" do |migration|
      assert_match(/AddTitleAndDescriptionTranslationsToAdminArticles/, migration)
      assert_match(/add_column :admin_articles, :title_translations, :json/, migration)
      assert_match(/add_column :admin_articles, :description_translations, :json/, migration)
    end
  end

  test "migration inherits from correct ActiveRecord version" do
    run_generator ["Widget", "name"]

    assert_migration "db/migrate/add_name_translations_to_widgets.rb" do |migration|
      # Should use current AR migration version
      assert_match(/< ActiveRecord::Migration\[\d+\.\d+\]/, migration)
    end
  end
end
