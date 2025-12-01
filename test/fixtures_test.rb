# frozen_string_literal: true

require_relative "test_helper"

# Test that fixtures work correctly with internationalized attributes
# This demonstrates proper YAML format for translation columns
class FixturesTest < Minitest::Test
  FIXTURES_PATH = File.expand_path("fixtures", __dir__)

  class << self
    def load_fixtures
      return if @fixtures_loaded

      Article.delete_all
      ActiveRecord::FixtureSet.create_fixtures(FIXTURES_PATH, ["articles"])
      @fixtures_loaded = true
    end
  end

  def setup
    I18n.locale = :en
  end

  def before_setup
    self.class.load_fixtures
    super
  end

  # ===================
  # Fixture Loading
  # ===================

  def test_fixtures_load_correct_count
    assert_equal(3, Article.count)
  end

  def test_fixture_nested_format_with_translations
    # Find the Hello World article using international query
    article = Article.international(title: "Hello World", locale: :en).first!

    assert_equal("Hello World", article.title_en)
    assert_equal("Hallo Welt", article.title_de)
    assert_equal("A greeting post", article.description_en)
  end

  def test_fixture_german_only_article
    article = Article.find_by!(status: "draft")

    assert_equal("Nur auf Deutsch", article.title_de)
    assert_nil(article.title_en)
  end

  def test_fixture_inline_hash_format
    # Find the Japanese article
    article = Article.international(title: "日本文化", locale: :ja).first!

    assert_equal("Japanese Culture", article.title_en)
    assert_equal("日本文化", article.title_ja)
  end

  def test_fixture_fallback_works
    article = Article.international(title: "Hello World", locale: :en).first!

    # German locale should return German translation
    I18n.locale = :de
    assert_equal("Hallo Welt", article.title)

    # French locale should fallback to English (default)
    I18n.locale = :fr
    assert_equal("Hello World", article.title)
  end
end
