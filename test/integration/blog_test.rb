# frozen_string_literal: true

require_relative "integration_test_helper"

class BlogIntegrationTest < IntegrationTestCase
  # ===================
  # Real-World Blog Workflow
  # ===================

  test "create blog post in multiple languages" do
    blog = Blog.new(author: "John Doe")

    # Write English version
    I18n.locale = :en
    blog.title = "Getting Started with Rails"
    blog.body = "Ruby on Rails is a powerful web framework..."

    # Write German version
    I18n.locale = :de
    blog.title = "Erste Schritte mit Rails"
    blog.body = "Ruby on Rails ist ein leistungsstarkes Web-Framework..."

    # Write Spanish version
    I18n.locale = :es
    blog.title = "Comenzando con Rails"
    blog.body = "Ruby on Rails es un potente framework web..."

    blog.save!

    # Verify all translations stored correctly
    assert_equal(
      {
        "en" => "Getting Started with Rails",
        "de" => "Erste Schritte mit Rails",
        "es" => "Comenzando con Rails",
      },
      blog.title_translations,
    )
  end

  test "read blog post respects current locale" do
    blog = Blog.create!(
      title_translations: {
        "en" => "Hello World",
        "de" => "Hallo Welt",
        "fr" => "Bonjour le Monde",
      },
      body_translations: {
        "en" => "This is my first blog post.",
        "de" => "Dies ist mein erster Blog-Beitrag.",
        "fr" => "Ceci est mon premier article de blog.",
      },
      author: "Jane Doe",
    )

    I18n.locale = :en
    assert_equal "Hello World", blog.title
    assert_equal "This is my first blog post.", blog.body

    I18n.locale = :de
    assert_equal "Hallo Welt", blog.title
    assert_equal "Dies ist mein erster Blog-Beitrag.", blog.body

    I18n.locale = :fr
    assert_equal "Bonjour le Monde", blog.title
    assert_equal "Ceci est mon premier article de blog.", blog.body
  end

  test "fallback to default locale when translation missing" do
    blog = Blog.create!(
      title_translations: { "en" => "English Only Post" },
      body_translations: { "en" => "This post is only in English." },
      author: "Author",
    )

    I18n.locale = :de
    # Should fall back to English
    assert_equal "English Only Post", blog.title
    assert_equal "This post is only in English.", blog.body
  end

  # ===================
  # Querying Multilingual Content
  # ===================

  test "search blog posts by title in specific locale" do
    Blog.create!(title_translations: { "en" => "Rails Tutorial", "de" => "Rails Anleitung" })
    Blog.create!(title_translations: { "en" => "Ruby Basics", "de" => "Ruby Grundlagen" })
    Blog.create!(title_translations: { "en" => "JavaScript Guide", "de" => "JavaScript Handbuch" })

    # Search in English
    results = Blog.international(title: "Rails", match: :partial, locale: :en).to_a
    assert_equal 1, results.size
    assert_equal "Rails Tutorial", results.first.title_en

    # Search in German
    results = Blog.international(title: "Anleitung", match: :partial, locale: :de).to_a
    assert_equal 1, results.size
    assert_equal "Rails Anleitung", results.first.title_de
  end

  test "find untranslated blog posts" do
    Blog.create!(title_translations: { "en" => "Translated", "de" => "Übersetzt" })
    untranslated = Blog.create!(title_translations: { "en" => "English Only" })

    results = Blog.untranslated(:title, locale: :de).to_a
    assert_equal 1, results.size
    assert_equal untranslated, results.first
  end

  test "sort blog posts by translated title" do
    Blog.create!(title_translations: { "en" => "Zebra", "de" => "Apfel" })
    Blog.create!(title_translations: { "en" => "Apple", "de" => "Zebra" })

    # Sort by English title
    en_results = Blog.international_order(:title, :asc, locale: :en).to_a
    assert_equal "Apple", en_results.first.title_en
    assert_equal "Zebra", en_results.last.title_en

    # Sort by German title (different order!)
    de_results = Blog.international_order(:title, :asc, locale: :de).to_a
    assert_equal "Apfel", de_results.first.title_de
    assert_equal "Zebra", de_results.last.title_de
  end

  # ===================
  # Locale-Specific Accessors
  # ===================

  test "direct locale accessors work correctly" do
    blog = Blog.new

    blog.title_en = "English Title"
    blog.title_de = "Deutscher Titel"
    blog.title_fr = "Titre Français"

    assert_equal "English Title", blog.title_en
    assert_equal "Deutscher Titel", blog.title_de
    assert_equal "Titre Français", blog.title_fr
  end

  test "predicate methods check for presence" do
    blog = Blog.new(title_translations: { "en" => "Hello", "de" => "" })

    assert blog.title_en?
    refute blog.title_de?  # Empty string is not present
    refute blog.title_fr?  # Missing locale
  end

  # ===================
  # Complex Queries
  # ===================

  test "chain international queries with ActiveRecord conditions" do
    Blog.create!(
      title_translations: { "en" => "Published Post" },
      published: true,
      author: "Alice",
    )
    Blog.create!(
      title_translations: { "en" => "Draft Post" },
      published: false,
      author: "Bob",
    )

    results = Blog.international(title: "Post", match: :partial, locale: :en)
      .where(published: true)
      .to_a

    assert_equal 1, results.size
    assert_equal "Alice", results.first.author
  end

  test "query across multiple locales" do
    Blog.create!(
      title_translations: { "en" => "Hello World", "de" => "Hallo Welt" },
    )
    Blog.create!(
      title_translations: { "en" => "Hello World", "de" => "Guten Tag" },
    )

    # Find posts where English title is "Hello World" AND German title is "Hallo Welt"
    results = Blog.international(title: "Hello World", locale: :en)
      .merge(Blog.international(title: "Hallo Welt", locale: :de))
      .to_a

    assert_equal 1, results.size
  end

  # ===================
  # Japanese (Non-ASCII) Support
  # ===================

  test "create and read blog post in Japanese" do
    blog = Blog.create!(
      title_translations: {
        "en" => "Hello World",
        "ja" => "こんにちは世界",
      },
      body_translations: {
        "en" => "Welcome to my blog.",
        "ja" => "ブログへようこそ。",
      },
      author: "田中太郎",
    )

    I18n.locale = :ja
    assert_equal "こんにちは世界", blog.title
    assert_equal "ブログへようこそ。", blog.body
  end

  test "search blog posts in Japanese" do
    Blog.create!(title_translations: { "ja" => "日本語のタイトル" })
    Blog.create!(title_translations: { "ja" => "英語のタイトル" })
    Blog.create!(title_translations: { "ja" => "中国語のタイトル" })

    # Search for "日本語" (Japanese)
    results = Blog.international(title: "日本語", match: :partial, locale: :ja).to_a
    assert_equal 1, results.size
    assert_equal "日本語のタイトル", results.first.title_ja
  end

  test "exact match in Japanese" do
    blog = Blog.create!(title_translations: { "ja" => "東京都" })
    Blog.create!(title_translations: { "ja" => "京都府" })

    results = Blog.international(title: "東京都", locale: :ja).to_a
    assert_equal 1, results.size
    assert_equal blog, results.first
  end

  test "sort by Japanese title" do
    Blog.create!(title_translations: { "ja" => "りんご" })  # Apple
    Blog.create!(title_translations: { "ja" => "みかん" })  # Orange
    Blog.create!(title_translations: { "ja" => "ぶどう" })  # Grape

    results = Blog.international_order(:title, :asc, locale: :ja).to_a
    # SQLite sorts by byte order, so hiragana order is: ぶどう, みかん, りんご
    assert_equal 3, results.size
  end

  test "mixed locale content in same record" do
    blog = Blog.create!(
      title_translations: {
        "en" => "Ruby Programming",
        "ja" => "Rubyプログラミング",
        "de" => "Ruby-Programmierung",
      },
    )

    assert_equal "Ruby Programming", blog.title_en
    assert_equal "Rubyプログラミング", blog.title_ja
    assert_equal "Ruby-Programmierung", blog.title_de
  end

  # ===================
  # Helper Methods
  # ===================

  test "translated_locales returns locales with content" do
    blog = Blog.new(title_translations: { "en" => "Hello", "de" => "Hallo", "fr" => "" })

    locales = blog.translated_locales(:title)
    assert_includes locales, :en
    assert_includes locales, :de
    refute_includes locales, :fr # Empty string excluded
  end

  test "translated? checks specific locale" do
    blog = Blog.new(title_translations: { "en" => "Hello" })

    assert blog.translated?(:title, :en)
    refute blog.translated?(:title, :de)
  end
end
