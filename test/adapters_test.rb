# frozen_string_literal: true

require "test_helper"

class AdaptersTest < Minitest::Test
  # ===================
  # SQLite Adapter
  # ===================

  def test_sqlite_json_extract
    adapter = Internationalize::Adapters::SQLite.new

    assert_equal(
      "json_extract(title_translations, '$.en')",
      adapter.json_extract("title_translations", :en),
    )
  end

  def test_sqlite_like_insensitive
    adapter = Internationalize::Adapters::SQLite.new
    sql, type = adapter.like_insensitive("title_translations", :en)

    assert_equal("json_extract(title_translations, '$.en') LIKE ? ESCAPE '\\'", sql)
    assert_equal(:like, type)
  end

  def test_sqlite_like_sensitive
    adapter = Internationalize::Adapters::SQLite.new
    sql, type = adapter.like_sensitive("title_translations", :en)

    assert_equal("json_extract(title_translations, '$.en') GLOB ?", sql)
    assert_equal(:glob, type)
  end

  def test_sqlite_like_pattern
    adapter = Internationalize::Adapters::SQLite.new

    assert_equal("%hello%", adapter.like_pattern("hello"))
    assert_equal("%100\\%%", adapter.like_pattern("100%"))
    assert_equal("%test\\_%", adapter.like_pattern("test_"))
  end

  def test_sqlite_glob_pattern
    adapter = Internationalize::Adapters::SQLite.new

    assert_equal("*hello*", adapter.glob_pattern("hello"))
    assert_equal("*test[*]*", adapter.glob_pattern("test*"))
    assert_equal("*test[?]*", adapter.glob_pattern("test?"))
  end

  # ===================
  # PostgreSQL Adapter
  # ===================

  def test_postgresql_json_extract
    adapter = Internationalize::Adapters::PostgreSQL.new

    assert_equal(
      "title_translations->>'en'",
      adapter.json_extract("title_translations", :en),
    )
  end

  def test_postgresql_like_insensitive
    adapter = Internationalize::Adapters::PostgreSQL.new
    sql, type = adapter.like_insensitive("title_translations", :en)

    assert_equal("title_translations->>'en' ILIKE ?", sql)
    assert_equal(:like, type)
  end

  def test_postgresql_like_sensitive
    adapter = Internationalize::Adapters::PostgreSQL.new
    sql, type = adapter.like_sensitive("title_translations", :en)

    assert_equal("title_translations->>'en' LIKE ?", sql)
    assert_equal(:like, type)
  end

  def test_postgresql_like_pattern
    adapter = Internationalize::Adapters::PostgreSQL.new

    assert_equal("%hello%", adapter.like_pattern("hello"))
    assert_equal("%100\\%%", adapter.like_pattern("100%"))
  end

  def test_postgresql_glob_pattern_same_as_like
    adapter = Internationalize::Adapters::PostgreSQL.new

    # PostgreSQL doesn't have GLOB, so glob_pattern returns LIKE pattern
    assert_equal("%hello%", adapter.glob_pattern("hello"))
  end

  # ===================
  # MySQL Adapter
  # ===================

  def test_mysql_json_extract
    adapter = Internationalize::Adapters::MySQL.new

    assert_equal(
      "title_translations->>'$.en'",
      adapter.json_extract("title_translations", :en),
    )
  end

  def test_mysql_like_insensitive
    adapter = Internationalize::Adapters::MySQL.new
    sql, type = adapter.like_insensitive("title_translations", :en)

    assert_equal("title_translations->>'$.en' LIKE ?", sql)
    assert_equal(:like, type)
  end

  def test_mysql_like_sensitive
    adapter = Internationalize::Adapters::MySQL.new
    sql, type = adapter.like_sensitive("title_translations", :en)

    assert_equal("title_translations->>'$.en' LIKE BINARY ?", sql)
    assert_equal(:like, type)
  end

  def test_mysql_like_pattern
    adapter = Internationalize::Adapters::MySQL.new

    assert_equal("%hello%", adapter.like_pattern("hello"))
    assert_equal("%100\\%%", adapter.like_pattern("100%"))
  end

  def test_mysql_glob_pattern_same_as_like
    adapter = Internationalize::Adapters::MySQL.new

    # MySQL doesn't have GLOB, so glob_pattern returns LIKE pattern
    assert_equal("%hello%", adapter.glob_pattern("hello"))
  end

  def test_mysql_json_extract_sanitizes_locale
    adapter = Internationalize::Adapters::MySQL.new

    # Normal locale
    assert_equal(
      "title_translations->>'$.en'",
      adapter.json_extract("title_translations", :en),
    )

    # Injection attempt - dangerous chars are stripped
    sql = adapter.json_extract("title_translations", "en'; DROP TABLE")
    assert_equal("title_translations->>'$.enDROPTABLE'", sql)
  end

  # ===================
  # Adapter Resolution
  # ===================

  def test_resolves_correct_adapter
    adapter = Internationalize::Adapters.resolve

    case DATABASE_ADAPTER
    when "postgresql", "postgres"
      assert_instance_of(Internationalize::Adapters::PostgreSQL, adapter)
    else
      assert_instance_of(Internationalize::Adapters::SQLite, adapter)
    end
  end

  def test_unsupported_adapter_raises_error
    mock_connection = Object.new
    def mock_connection.adapter_name
      "oracle"
    end

    error = assert_raises(Internationalize::Adapters::UnsupportedAdapter) do
      Internationalize::Adapters.resolve(mock_connection)
    end

    assert_includes(error.message, "oracle")
    assert_includes(error.message, "not supported")
  end

  def test_resolve_with_postgresql_adapter
    mock_connection = Object.new
    def mock_connection.adapter_name
      "postgresql"
    end

    adapter = Internationalize::Adapters.resolve(mock_connection)

    assert_instance_of(Internationalize::Adapters::PostgreSQL, adapter)
  end

  def test_resolve_with_mysql_adapter
    mock_connection = Object.new
    def mock_connection.adapter_name
      "mysql2"
    end

    adapter = Internationalize::Adapters.resolve(mock_connection)

    assert_instance_of(Internationalize::Adapters::MySQL, adapter)
  end

  def test_resolve_with_trilogy_adapter
    mock_connection = Object.new
    def mock_connection.adapter_name
      "trilogy"
    end

    adapter = Internationalize::Adapters.resolve(mock_connection)

    assert_instance_of(Internationalize::Adapters::MySQL, adapter)
  end

  # ===================
  # Base Adapter Abstract Methods
  # ===================

  def test_base_adapter_json_extract_raises_not_implemented
    adapter = Internationalize::Adapters::Base.new

    error = assert_raises(NotImplementedError) do
      adapter.json_extract("column", :en)
    end

    assert_includes(error.message, "must implement #json_extract")
  end

  def test_base_adapter_like_insensitive_raises_not_implemented
    adapter = Internationalize::Adapters::Base.new

    error = assert_raises(NotImplementedError) do
      adapter.like_insensitive("column", :en)
    end

    assert_includes(error.message, "must implement #like_insensitive")
  end

  def test_base_adapter_like_sensitive_raises_not_implemented
    adapter = Internationalize::Adapters::Base.new

    error = assert_raises(NotImplementedError) do
      adapter.like_sensitive("column", :en)
    end

    assert_includes(error.message, "must implement #like_sensitive")
  end

  def test_base_adapter_sanitize_locale
    adapter = Internationalize::Adapters::Base.new

    # Normal locales pass through
    assert_equal("en", adapter.sanitize_locale(:en))
    assert_equal("de", adapter.sanitize_locale("de"))
    assert_equal("pt-BR", adapter.sanitize_locale("pt-BR"))
    assert_equal("zh_CN", adapter.sanitize_locale("zh_CN"))

    # SQL injection characters are stripped (quotes, semicolons, spaces, etc.)
    # Only alphanumeric, underscore, and hyphen are allowed
    sanitized = adapter.sanitize_locale("en'; DROP TABLE users; --")
    refute_includes(sanitized, "'")
    refute_includes(sanitized, ";")
    refute_includes(sanitized, " ")
    # Hyphens are allowed (for locales like pt-BR), but the dangerous chars are gone
    assert_equal("enDROPTABLEusers--", sanitized)

    # Pure injection attempts have dangerous chars stripped
    # "' OR '1'='1" -> "OR11" (quotes and equals stripped)
    assert_equal("OR11", adapter.sanitize_locale("' OR '1'='1"))
  end

  def test_sqlite_json_extract_sanitizes_locale
    adapter = Internationalize::Adapters::SQLite.new

    # Normal locale
    assert_equal(
      "json_extract(title_translations, '$.en')",
      adapter.json_extract("title_translations", :en),
    )

    # Injection attempt - dangerous chars are stripped, safe chars remain
    sql = adapter.json_extract("title_translations", "en'; DROP TABLE")
    assert_equal("json_extract(title_translations, '$.enDROPTABLE')", sql)
    # Key: no way to break out of the JSON path string
    refute_match(/\$\.[^']*'/, sql.sub("'$.", "")) # No unescaped quotes in path
  end

  def test_postgresql_json_extract_sanitizes_locale
    adapter = Internationalize::Adapters::PostgreSQL.new

    # Normal locale
    assert_equal(
      "title_translations->>'en'",
      adapter.json_extract("title_translations", :en),
    )

    # Injection attempt - dangerous chars are stripped, safe chars remain
    sql = adapter.json_extract("title_translations", "en'; DROP TABLE")
    assert_equal("title_translations->>'enDROPTABLE'", sql)
    # Key: no way to break out of the quoted string
  end
end

class QueryAdapterIntegrationTest < InternationalizeTestCase
  def setup
    super
    @hello = Article.create!(
      title_translations: { "en" => "Hello World", "de" => "Hallo Welt" },
      status: "published",
    )
  end

  def test_international_uses_correct_adapter
    # This test verifies the international method correctly uses the adapter
    # by checking the generated SQL contains the expected syntax
    sql = Article.international(title: "Hello World", locale: :en).to_sql

    case DATABASE_ADAPTER
    when "postgresql", "postgres"
      assert_includes(sql, "title_translations")
      assert_includes(sql, "->>")
      assert_includes(sql, "'en'")
    else
      assert_includes(sql, "json_extract")
      assert_includes(sql, "title_translations")
      assert_includes(sql, "$.en")
    end
  end

  def test_international_partial_generates_correct_sql
    sql = Article.international(title: "Hello", match: :partial, locale: :en).to_sql

    case DATABASE_ADAPTER
    when "postgresql", "postgres"
      assert_includes(sql, "->>")
      assert_includes(sql, "ILIKE")
    else
      assert_includes(sql, "json_extract")
      assert_includes(sql, "LIKE")
    end
  end

  def test_international_order_generates_correct_sql
    sql = Article.international_order(:title, :desc, locale: :en).to_sql

    case DATABASE_ADAPTER
    when "postgresql", "postgres"
      assert_includes(sql, "->>")
    else
      assert_includes(sql, "json_extract")
    end
    assert_includes(sql, "DESC")
  end
end
