# frozen_string_literal: true

require "test_helper"

class QueryTest < InternationalizeTestCase
  def setup
    super
    @hello = Article.create!(
      title_translations: { "en" => "Hello World", "de" => "Hallo Welt" },
      description_translations: { "en" => "A greeting" },
      status: "published",
      published: true,
    )
    @goodbye = Article.create!(
      title_translations: { "en" => "Goodbye", "de" => "Auf Wiedersehen" },
      description_translations: { "en" => "A farewell", "de" => "Ein Abschied" },
      status: "draft",
      published: false,
    )
    @untranslated = Article.create!(
      title_translations: { "en" => "English Only" },
      status: "published",
      published: true,
    )
  end

  # ===================
  # Basic international() Query (Exact Match)
  # ===================

  def test_international_finds_exact_translation
    results = Article.international(title: "Hello World").to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_respects_locale_option
    results = Article.international(title: "Hallo Welt", locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_uses_current_locale_by_default
    I18n.locale = :de
    results = Article.international(title: "Hallo Welt").to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_returns_empty_for_wrong_locale
    results = Article.international(title: "Hello World", locale: :de).to_a

    assert_empty(results)
  end

  def test_international_with_multiple_conditions
    results = Article.international(title: "Hello World", description: "A greeting").to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_raises_for_non_international_attributes
    error = assert_raises(ArgumentError) do
      Article.international(status: "published").to_a
    end

    assert_includes(error.message, "status is not an international attribute")
    assert_includes(error.message, "Use standard ActiveRecord methods")
  end

  # ===================
  # international_not() (Exclusion)
  # ===================

  def test_international_not_removes_matching_records
    results = Article.international_not(title: "Hello World").to_a

    assert_equal(2, results.size)
    refute_includes(results, @hello)
  end

  def test_international_not_raises_for_non_international_attributes
    error = assert_raises(ArgumentError) do
      Article.international_not(status: "draft").to_a
    end

    assert_includes(error.message, "status is not an international attribute")
  end

  def test_international_not_with_locale_option
    results = Article.international_not(title: "Hallo Welt", locale: :de).to_a

    assert_equal(2, results.size)
    refute_includes(results, @hello)
  end

  # ===================
  # international(match: :partial) (LIKE)
  # ===================

  def test_international_partial_finds_partial_matches
    results = Article.international(title: "Hello", match: :partial).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_partial_is_case_insensitive_by_default
    results = Article.international(title: "hello", match: :partial).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_partial_case_sensitive
    results = Article.international(title: "hello", match: :partial, case_sensitive: true).to_a

    assert_empty(results)
  end

  def test_international_partial_case_sensitive_finds_exact_case
    results = Article.international(title: "Hello", match: :partial, case_sensitive: true).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_partial_finds_substring
    results = Article.international(title: "orld", match: :partial).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_partial_escapes_special_characters
    article = Article.create!(title_translations: { "en" => "100% complete" })
    results = Article.international(title: "100%", match: :partial).to_a

    assert_equal(1, results.size)
    assert_equal(article, results.first)
  end

  def test_international_partial_with_locale_option
    results = Article.international(title: "Welt", match: :partial, locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  # ===================
  # international_order()
  # ===================

  def test_international_order_orders_by_translation_asc
    results = Article.international_order(:title, :asc).to_a

    assert_equal(@untranslated, results.first)  # "English Only"
    assert_equal(@hello, results.last)          # "Hello World"
  end

  def test_international_order_orders_by_translation_desc
    results = Article.international_order(:title, :desc).to_a

    assert_equal(@hello, results.first)         # "Hello World"
  end

  def test_international_order_respects_locale_option
    results = Article.international_order(:title, :asc, locale: :de).to_a

    assert_equal(3, results.size)

    translated = results.select { |r| r.title_translations["de"].present? }
    assert_equal(2, translated.size)

    auf_idx = results.index(@goodbye)
    hallo_idx = results.index(@hello)
    assert(auf_idx < hallo_idx, "Expected 'Auf Wiedersehen' before 'Hallo Welt'")
  end

  def test_international_order_with_invalid_direction_defaults_to_asc
    results = Article.international_order(:title, :invalid).to_a

    assert_equal(3, results.size)
    assert_equal(@untranslated, results.first)  # "English Only"
  end

  def test_international_order_raises_for_non_international_attributes
    error = assert_raises(ArgumentError) do
      Article.international_order(:status, :desc).to_a
    end

    assert_includes(error.message, "status is not an international attribute")
  end

  # ===================
  # translated() / untranslated()
  # ===================

  def test_translated_finds_records_with_translation
    results = Article.translated(:title, locale: :de).to_a

    assert_equal(2, results.size)
    assert_includes(results, @hello)
    assert_includes(results, @goodbye)
    refute_includes(results, @untranslated)
  end

  def test_translated_with_multiple_attributes
    results = Article.translated(:title, :description, locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@goodbye, results.first)
  end

  def test_untranslated_finds_records_missing_translation
    results = Article.untranslated(:title, locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@untranslated, results.first)
  end

  def test_untranslated_finds_empty_translations
    article = Article.create!(title_translations: { "en" => "Test", "de" => "" })
    results = Article.untranslated(:title, locale: :de).to_a

    assert_includes(results, article)
  end

  def test_translated_uses_current_locale_by_default
    I18n.locale = :de
    results = Article.translated(:title).to_a

    assert_equal(2, results.size)
  end

  def test_untranslated_uses_current_locale_by_default
    I18n.locale = :de
    results = Article.untranslated(:title).to_a

    assert_equal(1, results.size)
  end

  # ===================
  # Chaining with AR Methods
  # ===================

  def test_international_combined_with_ar_where
    results = Article.international(title: "Hello World")
      .where(published: true)
      .to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_partial_combined_with_ar_where
    results = Article.international(title: "Hello", match: :partial)
      .where(status: "published")
      .to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_combined_with_ar_order
    Article.create!(
      title_translations: { "en" => "Hello World" },
      status: "draft",
      published: false,
    )

    results = Article.international(title: "Hello World")
      .order(created_at: :asc)
      .to_a

    assert_equal(2, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_order_then_ar_limit
    results = Article.where(published: true)
      .merge(Article.international_order(:title, :asc))
      .limit(1)
      .to_a

    assert_equal(1, results.size)
    assert_equal(@untranslated, results.first) # "English Only"
  end

  def test_international_with_limit
    Article.create!(title_translations: { "en" => "Hello World" })

    results = Article.international(title: "Hello World")
      .limit(1)
      .to_a

    assert_equal(1, results.size)
  end

  def test_translated_combined_with_ar_where
    results = Article.translated(:title, locale: :de)
      .where(status: "published")
      .to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_complex_chain
    results = Article.international(title: "Hello", match: :partial)
      .where(published: true, status: "published")
      .merge(Article.international_order(:title, :desc))
      .limit(10)
      .to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  # ===================
  # Delegation / ActiveRecord Methods
  # ===================

  def test_count
    count = Article.international(title: "Hello World").count

    assert_equal(1, count)
  end

  def test_exists
    assert(Article.international(title: "Hello World").exists?)
    refute(Article.international(title: "Nonexistent").exists?)
  end

  def test_first
    result = Article.international(title: "Hello World").first

    assert_equal(@hello, result)
  end

  def test_pluck
    ids = Article.international(title: "Hello World").pluck(:id)

    assert_equal([@hello.id], ids)
  end

  def test_find_each
    collected = []
    Article.international(title: "Hello World").find_each { |a| collected << a }

    assert_equal([@hello], collected)
  end

  def test_to_sql
    sql = Article.international(title: "Hello World").to_sql

    assert_includes(sql, "title_translations")
    assert_includes(sql, "Hello World")

    case DATABASE_ADAPTER
    when "postgresql", "postgres"
      assert_includes(sql, "->>")
    else
      assert_includes(sql, "json_extract")
    end
  end

  def test_last
    result = Article.international(title: "Hello World").last

    assert_equal(@hello, result)
  end

  def test_empty
    refute(Article.international(title: "Hello World").empty?)
    assert(Article.international(title: "Nonexistent").empty?)
  end

  def test_any
    assert(Article.international(title: "Hello World").any?)
    refute(Article.international(title: "nonexistent").any?)
  end

  def test_ids
    ids = Article.international(title: "Hello World").ids

    assert_equal([@hello.id], ids)
  end

  # ===================
  # Edge Cases
  # ===================

  def test_empty_conditions
    results = Article.international.to_a

    assert_equal(3, results.size)
  end

  def test_nil_handling
    article = Article.create!(title_translations: nil)

    results = Article.untranslated(:title).to_a
    assert_includes(results, article)
  end

  # ===================
  # Non-International Attributes Raise Error
  # ===================

  def test_international_raises_for_non_international_attribute
    error = assert_raises(ArgumentError) do
      Article.international(status: "publish").to_a
    end

    assert_includes(error.message, "status is not an international attribute")
  end

  def test_international_partial_raises_for_non_international_attribute
    error = assert_raises(ArgumentError) do
      Article.international(status: "publish", match: :partial).to_a
    end

    assert_includes(error.message, "status is not an international attribute")
  end

  # ===================
  # Adapter-Specific SQL Branches (for full branch coverage)
  # ===================

  def test_international_partial_case_sensitive_postgresql_uses_like
    pg_adapter = Internationalize::Adapters::PostgreSQL.new
    Internationalize::Adapters.stub(:resolve, pg_adapter) do
      sql = Article.international(title: "Hello", match: :partial, case_sensitive: true).to_sql
      assert_includes(sql, "LIKE")
      assert_includes(sql, "%Hello%")
    end
  end

  def test_international_partial_case_sensitive_sqlite_uses_glob
    sqlite_adapter = Internationalize::Adapters::SQLite.new
    Internationalize::Adapters.stub(:resolve, sqlite_adapter) do
      sql = Article.international(title: "Hello", match: :partial, case_sensitive: true).to_sql
      assert_includes(sql, "GLOB")
      assert_includes(sql, "*Hello*")
    end
  end

  def test_international_partial_case_sensitive_postgresql_uses_like_pattern
    # Test that PostgreSQL uses like_pattern (not glob_pattern) for case-sensitive partial
    # This exercises the `pattern_type == :glob ? glob : like` branch when pattern_type is :like
    pg_adapter = Internationalize::Adapters::PostgreSQL.new
    Internationalize::Adapters.stub(:resolve, pg_adapter) do
      sql = Article.international(title: "Hello", match: :partial, case_sensitive: true).to_sql
      assert_includes(sql, "LIKE")
      assert_includes(sql, "%Hello%")
      refute_includes(sql, "GLOB")
    end
  end

  def test_international_not_with_translated_attribute
    # Ensure international_not works with translated attributes
    results = Article.international_not(title: "Hello World", locale: :en).to_a

    assert_equal(2, results.size)
    refute_includes(results, @hello)
  end

  # Additional tests for branch coverage
  def test_international_partial_insensitive_postgresql
    # Test case-insensitive search on translated attribute with PostgreSQL
    pg_adapter = Internationalize::Adapters::PostgreSQL.new
    Internationalize::Adapters.stub(:resolve, pg_adapter) do
      sql = Article.international(title: "hello", match: :partial).to_sql
      assert_includes(sql, "ILIKE")
    end
  end

  # ===================
  # Translated/Untranslated with non-international attributes
  # ===================

  def test_translated_ignores_non_international_attributes
    results = Article.translated(:title, :status, locale: :de).to_a

    assert_equal(2, results.size)
  end

  def test_untranslated_ignores_non_international_attributes
    results = Article.untranslated(:title, :status, locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@untranslated, results.first)
  end

  # ===================
  # Access with Explicit Locale
  # ===================

  def test_attribute_getter_with_explicit_locale
    article = Article.new(title_translations: { "en" => "Hello", "de" => "Hallo" })

    assert_equal("Hallo", article.title(:de))
  end

  # ===================
  # Order Precedence Tests
  # ===================

  def test_international_order_before_ar_order
    Article.create!(title_translations: { "en" => "Alpha" }, status: "draft")
    Article.create!(title_translations: { "en" => "Alpha" }, status: "published")

    # international_order should be applied first, then AR order for same titles
    results = Article.international_order(:title, :asc)
      .order(status: :asc)
      .to_a

    # Find the two "Alpha" articles
    alphas = results.select { |a| a.title == "Alpha" }
    assert_equal(2, alphas.size)

    # Within same title, status should be ordered (draft < published)
    alpha_statuses = alphas.map(&:status)
    assert_equal(["draft", "published"], alpha_statuses)
  end

  def test_ar_order_before_international_order
    Article.delete_all
    Article.create!(title_translations: { "en" => "Alpha" }, status: "draft")
    Article.create!(title_translations: { "en" => "Beta" }, status: "draft")
    Article.create!(title_translations: { "en" => "Gamma" }, status: "published")

    # AR order first, then international_order
    results = Article.order(status: :asc)
      .merge(Article.international_order(:title, :asc))
      .to_a

    # drafts should come first (status order), then within drafts (title order)
    drafts = results.select { |a| a.status == "draft" }
    assert_equal(2, drafts.size)
    assert_equal(["Alpha", "Beta"], drafts.map(&:title))
  end

  # ===================
  # international_where() Alias
  # ===================

  def test_international_where_is_alias_for_international_query
    results = Article.international_where(title: "Hello World").to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_where_with_partial_match
    results = Article.international_where(title: "hello", match: :partial).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end

  def test_international_where_with_locale
    results = Article.international_where(title: "Hallo Welt", locale: :de).to_a

    assert_equal(1, results.size)
    assert_equal(@hello, results.first)
  end
end
