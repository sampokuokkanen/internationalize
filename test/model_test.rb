# frozen_string_literal: true

require "test_helper"

class InternationalizeConfigTest < Minitest::Test
  def teardown
    # Reset configuration
    Internationalize.available_locales = nil
  end

  def test_configure_block
    Internationalize.configure do |config|
      config.available_locales = [:en, :de]
    end

    assert_equal([:en, :de], Internationalize.available_locales)
  end

  def test_locales_uses_available_locales_when_set
    Internationalize.available_locales = [:en, :de, :fr]

    assert_equal([:en, :de, :fr], Internationalize.locales)
  end

  def test_locales_uses_i18n_locales_when_not_set
    Internationalize.available_locales = nil

    assert_equal(I18n.available_locales, Internationalize.locales)
  end
end

class ModelTest < InternationalizeTestCase
  # ===================
  # Basic Accessors
  # ===================

  def test_sets_translation_for_current_locale
    article = Article.new
    article.title = "Hello World"

    assert_equal({ "en" => "Hello World" }, article.title_translations)
  end

  def test_gets_translation_for_current_locale
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    assert_equal("Hello", article.title)
  end

  def test_sets_translation_for_specific_locale
    article = Article.new
    article.title_en = "Hello"
    article.title_de = "Hallo"

    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
    assert_equal({ "en" => "Hello", "de" => "Hallo" }, article.title_translations)
  end

  def test_gets_translation_for_specific_locale
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
  end

  def test_predicate_methods
    article = Article.new(title_translations: { "en" => "Hello", "de" => "" })

    assert(article.title?)
    assert(article.title_en?)
    refute(article.title_de?)
    refute(article.title_fr?)
  end

  def test_respects_locale_change
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    I18n.locale = :en
    assert_equal("Hello", article.title)

    I18n.locale = :de
    assert_equal("Hallo", article.title)
  end

  def test_setter_respects_locale_change
    article = Article.new

    I18n.locale = :en
    article.title = "Hello"

    I18n.locale = :de
    article.title = "Hallo"

    assert_equal({ "en" => "Hello", "de" => "Hallo" }, article.title_translations)
  end

  # ===================
  # Fallback Behavior
  # ===================

  def test_falls_back_to_default_locale
    article = Article.new(title_translations: { "en" => "Hello" })

    I18n.locale = :de
    assert_equal("Hello", article.title)
  end

  def test_no_fallback_when_translation_exists
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    I18n.locale = :de
    assert_equal("Hallo", article.title)
  end

  def test_no_fallback_for_default_locale
    article = Article.new(title_translations: { "de" => "Hallo" })

    I18n.locale = :en
    assert_nil(article.title)
  end

  # ===================
  # Bulk Translations
  # ===================

  def test_set_all_translations_at_once
    article = Article.new
    article.title_translations = { en: "Hello", de: "Hallo" }

    assert_equal({ "en" => "Hello", "de" => "Hallo" }, article.title_translations)
  end

  def test_translations_are_stringified
    article = Article.new
    article.title_translations = { en: "Hello", de: "Hallo" }

    assert_equal("Hello", article.title_translations["en"])
    assert_nil(article.title_translations[:en])
  end

  def test_translations_rejects_non_hash
    article = Article.new

    error = assert_raises(ArgumentError) { article.title_translations = "invalid" }
    assert_match(/must be a Hash/, error.message)

    error = assert_raises(ArgumentError) { article.title_translations = ["en", "Hello"] }
    assert_match(/must be a Hash/, error.message)
  end

  def test_translations_rejects_invalid_locales
    article = Article.new

    error = assert_raises(ArgumentError) { article.title_translations = { xx: "Invalid" } }
    assert_match(/Invalid locale 'xx'/, error.message)
    assert_match(/Allowed locales:/, error.message)
  end

  # ===================
  # Instance Helper Methods
  # ===================

  def test_translated_predicate
    article = Article.new(title_translations: { "en" => "Hello" })

    assert(article.translated?(:title, :en))
    refute(article.translated?(:title, :de))
  end

  def test_translated_locales
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo", "fr" => "" })

    assert_equal([:en, :de], article.translated_locales(:title))
  end

  # ===================
  # Creation Helpers
  # ===================

  def test_international_new_creates_instance_with_translations
    article = Article.international_new(
      title: { en: "Hello", de: "Hallo" },
      description: { en: "A greeting" },
    )

    assert(article.new_record?)
    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
    assert_equal("A greeting", article.description_en)
  end

  def test_international_new_passes_through_non_translated_attributes
    article = Article.international_new(
      title: { en: "Hello" },
      status: "published",
      published: true,
    )

    assert_equal("Hello", article.title_en)
    assert_equal("published", article.status)
    assert(article.published)
  end

  def test_international_create_saves_record
    article = Article.international_create(
      title: { en: "Hello", de: "Hallo" },
    )

    assert(article.persisted?)
    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
  end

  def test_international_create_bang_saves_record
    article = Article.international_create!(
      title: { en: "Hello", de: "Hallo" },
      status: "published",
    )

    assert(article.persisted?)
    assert_equal("Hello", article.title_en)
    assert_equal("published", article.status)
  end

  def test_international_create_with_mixed_attributes
    article = Article.international_create!(
      title: { en: "Hello", de: "Hallo" },
      description: { en: "Greeting", de: "Begrüßung" },
      status: "draft",
      published: false,
    )

    article.reload
    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
    assert_equal("Greeting", article.description_en)
    assert_equal("Begrüßung", article.description_de)
    assert_equal("draft", article.status)
    refute(article.published)
  end

  def test_international_create_bang_with_direct_string_uses_current_locale
    I18n.locale = :de
    article = Article.international_create!(title: "Achtung!")

    assert_equal("Achtung!", article.title_de)
    assert_nil(article.title_en)
    assert_equal({ "de" => "Achtung!" }, article.title_translations)
  end

  def test_international_create_with_direct_string_uses_current_locale
    I18n.locale = :de
    article = Article.international_create(title: "Achtung!")

    assert(article.persisted?)
    assert_equal("Achtung!", article.title_de)
    assert_nil(article.title_en)
  end

  def test_international_new_with_direct_string_uses_current_locale
    I18n.locale = :fr
    article = Article.international_new(title: "Bonjour", description: "Salutation")

    assert_equal("Bonjour", article.title_fr)
    assert_equal("Salutation", article.description_fr)
    assert_nil(article.title_en)
  end

  def test_international_create_with_mixed_string_and_hash
    I18n.locale = :en
    article = Article.international_create!(
      title: "Hello", # Direct string for current locale
      description: { en: "English desc", de: "German desc" }, # Hash for multiple
    )

    assert_equal("Hello", article.title_en)
    assert_nil(article.title_de)
    assert_equal("English desc", article.description_en)
    assert_equal("German desc", article.description_de)
  end

  # ===================
  # Persistence
  # ===================

  def test_persists_translations
    article = Article.create!(title_translations: { "en" => "Hello", "de" => "Hallo" })
    article.reload

    assert_equal("Hello", article.title_en)
    assert_equal("Hallo", article.title_de)
  end

  def test_updates_translations
    article = Article.create!(title_translations: { "en" => "Hello" })
    article.title_de = "Hallo"
    article.save!
    article.reload

    assert_equal({ "en" => "Hello", "de" => "Hallo" }, article.title_translations)
  end

  def test_multiple_international_attributes
    article = Article.new
    article.title = "Hello"
    article.description = "A description"

    assert_equal("Hello", article.title)
    assert_equal("A description", article.description)
    assert_equal({ "en" => "Hello" }, article.title_translations)
    assert_equal({ "en" => "A description" }, article.description_translations)
  end

  # ===================
  # Class Attributes
  # ===================

  def test_international_attributes_list
    assert_equal([:title, :description], Article.international_attributes)
    assert_equal([:name], Product.international_attributes)
  end

  def test_nil_translations_handling
    article = Article.new
    article.title_translations = nil

    assert_equal({}, article.title_translations)
    assert_nil(article.title)
  end

  def test_attribute_with_explicit_locale_parameter
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    assert_equal("Hallo", article.title(:de))
    assert_equal("Hello", article.title(:en))
  end

  def test_fallback_skipped_when_locale_matches_default
    # When querying default locale and value is nil, no fallback should occur
    article = Article.new(title_translations: { "de" => "Hallo" })

    I18n.locale = :en
    assert_nil(article.title)
  end

  def test_warns_when_column_missing_default
    # Create a table without default: {}
    ActiveRecord::Schema.define do
      create_table(:no_default_posts, force: true) do |t|
        t.json(:title_translations) # No default!
      end
    end

    warning_output = StringIO.new
    original_stderr = $stderr
    $stderr = warning_output

    begin
      Class.new(ActiveRecord::Base) do
        self.table_name = "no_default_posts"
        include Internationalize::Model

        international :title
      end
    ensure
      $stderr = original_stderr
    end

    output = warning_output.string
    assert_match(/missing.*default: \{\}/, output)
    assert_match(/no_default_posts\.title_translations/, output)
  end

  def test_rejects_hyphenated_locales
    original_locales = I18n.available_locales
    I18n.available_locales = [:en, :"zh-TW"]

    error = assert_raises(ArgumentError) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "articles"
        include Internationalize::Model

        international :title
      end
    end

    assert_match(/Locale 'zh-TW' contains a hyphen/, error.message)
    assert_match(/Use underscore format instead: :zh_TW/, error.message)
  ensure
    I18n.available_locales = original_locales
  end
end
