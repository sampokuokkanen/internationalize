# frozen_string_literal: true

require_relative "test_helper"

class ValidationsTest < InternationalizeTestCase
  # ===================
  # Uniqueness Validation
  # ===================

  def test_validates_uniqueness_per_locale
    ValidatedWithUniqueness.create!(title_en: "Hello")

    article = ValidatedWithUniqueness.new(title_en: "Hello")
    I18n.locale = :en

    refute(article.valid?)
    assert_includes(article.errors[:title_en], I18n.t("errors.messages.taken"))
  end

  def test_uniqueness_allows_same_value_different_locale
    ValidatedWithUniqueness.create!(title_en: "Hello", title_de: "Hallo")

    # Same German title, different English title - should be valid
    article = ValidatedWithUniqueness.new(title_en: "World", title_de: "Hallo")
    I18n.locale = :en

    # Only validates current locale (en), so de uniqueness not checked
    assert(article.valid?)
  end

  def test_uniqueness_excludes_self_on_update
    article = ValidatedWithUniqueness.create!(title_en: "Hello")
    I18n.locale = :en

    # Updating same record should be valid
    article.title_en = "Hello"
    assert(article.valid?)
  end

  def test_uniqueness_skips_blank_values
    article = ValidatedWithUniqueness.new
    I18n.locale = :en

    # Blank values should skip uniqueness check
    assert(article.valid?)
  end

  def test_uniqueness_different_values_same_locale
    ValidatedWithUniqueness.create!(title_en: "Hello")

    article = ValidatedWithUniqueness.new(title_en: "World")
    I18n.locale = :en

    assert(article.valid?)
  end

  # ===================
  # Multi-Locale Presence (Admin Interface)
  # ===================

  def test_validates_presence_for_specific_locales
    article = ValidatedWithLocales.new(title_en: "Hello")

    refute(article.valid?)
    assert_empty(article.errors[:title_en])
    assert_includes(article.errors[:title_de], I18n.t("errors.messages.blank"))
  end

  def test_specific_locales_passes_when_all_present
    article = ValidatedWithLocales.new(title_en: "Hello", title_de: "Hallo")

    assert(article.valid?)
  end

  def test_presence_validates_all_specified_locales
    article = ValidatedWithLocales.new

    refute(article.valid?)
    assert_includes(article.errors[:title_en], I18n.t("errors.messages.blank"))
    assert_includes(article.errors[:title_de], I18n.t("errors.messages.blank"))
  end

  def test_presence_without_locales_raises_error
    assert_raises(ArgumentError) do
      Class.new(ActiveRecord::Base) do
        self.table_name = "articles"
        include Internationalize::Model
        international :title
        validates_international :title, presence: true
      end
    end
  end

  # ===================
  # Standard Rails Validations (Recommended)
  # ===================

  def test_rails_presence_validation_works
    article = ValidatedWithRails.new
    I18n.locale = :en

    refute(article.valid?)
    assert_includes(article.errors[:title], I18n.t("errors.messages.blank"))
  end

  def test_rails_presence_passes_when_present
    article = ValidatedWithRails.new(title_en: "Hello")
    I18n.locale = :en

    assert(article.valid?)
  end

  def test_rails_length_validation_works
    article = ValidatedWithRails.new(title_en: "Hi")
    I18n.locale = :en

    refute(article.valid?)
    assert(article.errors[:title].any? { |e| e.include?("short") })
  end

  def test_rails_format_validation_works
    article = ValidatedWithRailsFormat.new(title_en: "Hello123")
    I18n.locale = :en

    refute(article.valid?)
    assert_includes(article.errors[:title], I18n.t("errors.messages.invalid"))
  end

  # ===================
  # Persistence with Validation
  # ===================

  def test_save_fails_with_invalid_data
    article = ValidatedWithUniqueness.new(title_en: "Hello")
    ValidatedWithUniqueness.create!(title_en: "Hello")
    I18n.locale = :en

    refute(article.save)
    assert(article.new_record?)
  end

  def test_save_succeeds_with_valid_data
    article = ValidatedWithUniqueness.new(title_en: "Hello")
    I18n.locale = :en

    assert(article.save)
    refute(article.new_record?)
  end
end
