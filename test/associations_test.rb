# frozen_string_literal: true

require "test_helper"

class AssociationsTest < InternationalizeTestCase
  def setup
    super

    # Create test data with associations
    @author = Author.create!(
      name_translations: { "en" => "John Doe", "de" => "Johann Doe" },
      bio_translations: { "en" => "A writer", "de" => "Ein Autor" },
      email: "john@example.com",
    )

    @other_author = Author.create!(
      name_translations: { "en" => "Jane Smith", "de" => "Jana Schmidt" },
      email: "jane@example.com",
    )

    @article1 = Article.create!(
      title_translations: { "en" => "Hello World", "de" => "Hallo Welt" },
      description_translations: { "en" => "A greeting" },
      author: @author,
      status: "published",
      published: true,
    )

    @article2 = Article.create!(
      title_translations: { "en" => "Goodbye", "de" => "Auf Wiedersehen" },
      author: @author,
      status: "draft",
      published: false,
    )

    @article3 = Article.create!(
      title_translations: { "en" => "Other Article" },
      author: @other_author,
      status: "published",
      published: true,
    )

    @comment1 = Comment.create!(
      body_translations: { "en" => "Great post!", "de" => "Toller Beitrag!" },
      article: @article1,
      author: @other_author,
    )

    @comment2 = Comment.create!(
      body_translations: { "en" => "Thanks!", "de" => "Danke!" },
      article: @article1,
      author: @author,
    )

    @category = Category.create!(
      name_translations: { "en" => "Electronics", "de" => "Elektronik" },
    )

    @subcategory = Category.create!(
      name_translations: { "en" => "Phones", "de" => "Handys" },
      parent: @category,
    )

    @product = Product.create!(
      name_translations: { "en" => "iPhone", "de" => "iPhone" },
      category: @subcategory,
      price: 999,
    )

    @tag1 = Tag.create!(name_translations: { "en" => "Tech", "de" => "Technik" })
    @tag2 = Tag.create!(name_translations: { "en" => "News", "de" => "Nachrichten" })

    @article1.tags << @tag1
    @article1.tags << @tag2
    @article2.tags << @tag1
  end

  # ===================
  # Basic Association Access
  # ===================

  def test_belongs_to_with_translations
    assert_equal(@author, @article1.author)
    assert_equal("John Doe", @article1.author.name)
    assert_equal("Johann Doe", @article1.author.name_de)
  end

  def test_has_many_with_translations
    articles = @author.articles

    assert_equal(2, articles.count)
    assert_equal(["Hello World", "Goodbye"].sort, articles.map(&:title).sort)
  end

  def test_has_many_through_with_translations
    comments = @article1.comments

    assert_equal(2, comments.count)
    assert_includes(comments.map(&:body), "Great post!")
    assert_includes(comments.map(&:body), "Thanks!")
  end

  def test_has_and_belongs_to_many_with_translations
    tags = @article1.tags

    assert_equal(2, tags.count)
    assert_includes(tags.map(&:name), "Tech")
    assert_includes(tags.map(&:name), "News")
  end

  def test_self_referential_association
    assert_equal(@category, @subcategory.parent)
    assert_equal("Electronics", @subcategory.parent.name)

    assert_equal([@subcategory], @category.children.to_a)
    assert_equal("Phones", @category.children.first.name)
  end

  # ===================
  # Querying with Joins
  # ===================

  def test_query_with_joins_on_belongs_to
    results = Article.joins(:author)
      .where(authors: { email: "john@example.com" })
      .international(title: "Hello World")
      .to_a

    assert_equal(1, results.size)
    assert_equal(@article1, results.first)
  end

  def test_query_with_joins_and_international
    results = Article.joins(:author)
      .where(status: "published")
      .to_a

    assert_equal(2, results.size)
  end

  def test_query_with_left_joins
    Article.create!(
      title_translations: { "en" => "No Author" },
      status: "published",
    )

    results = Article.left_joins(:author)
      .where(status: "published")
      .to_a

    assert_equal(3, results.size)
  end

  def test_query_with_includes_eager_loading
    results = Article.includes(:author)
      .where(status: "published")
      .to_a

    assert_equal(2, results.size)

    results.each do |article|
      article.author&.name
    end
  end

  def test_query_through_has_many
    results = Comment.joins(:article)
      .where(articles: { status: "published" })
      .international(body: "Great", match: :partial)
      .to_a

    assert_equal(1, results.size)
    assert_equal(@comment1, results.first)
  end

  def test_query_with_habtm_joins
    results = Article.joins(:tags)
      .where(status: "published")
      .to_a

    assert_includes(results, @article1)
  end

  # ===================
  # Complex Combined Queries
  # ===================

  def test_search_with_multiple_conditions
    results = Article.international(title: "Hello", match: :partial)
      .where(status: "published", published: true)
      .to_a

    assert_equal(1, results.size)
    assert_equal(@article1, results.first)
  end

  def test_search_and_sort_with_limit
    Article.create!(title_translations: { "en" => "Alpha" }, status: "published", published: true)
    Article.create!(title_translations: { "en" => "Zebra" }, status: "published", published: true)

    results = Article.where(published: true)
      .merge(Article.international_order(:title, :asc))
      .limit(3)
      .to_a

    assert_equal(3, results.size)
    assert_equal("Alpha", results.first.title)
  end

  def test_search_with_international_not
    results = Article.where(status: "published")
      .merge(Article.international_not(title: "Other Article"))
      .to_a

    assert_equal(1, results.size)
    assert_equal(@article1, results.first)
  end

  def test_translated_with_joins
    results = Article.joins(:author)
      .where(authors: { email: "john@example.com" })
      .translated(:title, locale: :de)
      .to_a

    assert_equal(2, results.size)
    assert_includes(results, @article1)
    assert_includes(results, @article2)
  end

  def test_untranslated_with_associations
    results = Article.where(author: @author)
      .untranslated(:description, locale: :de)
      .to_a

    assert_equal(2, results.size)
    assert_includes(results, @article1)
    assert_includes(results, @article2)
  end

  def test_chained_locale_queries_with_associations
    results = Article.includes(:author)
      .international(title: "Hello World")
      .merge(Article.translated(:title, locale: :de))
      .to_a

    assert_equal(1, results.size)
    assert_equal(@article1, results.first)
  end

  def test_complex_query_with_or_conditions
    query1 = Article.international(title: "Hello World")
    query2 = Article.international(title: "Goodbye")

    results = query1.or(query2).to_a

    assert_equal(2, results.size)
  end

  # ===================
  # Querying Across Multiple Models
  # ===================

  def test_subquery_pattern
    author_ids = Comment.distinct.pluck(:author_id)
    results = Article.where(author_id: author_ids)
      .where(status: "published")
      .to_a

    assert_equal(2, results.size)
  end

  def test_nested_association_query
    subcategory_ids = @category.children.pluck(:id)
    results = Product.where(category_id: subcategory_ids)
      .international(name: "iPhone")
      .to_a

    assert_equal(1, results.size)
    assert_equal(@product, results.first)
  end

  # ===================
  # Performance-Focused Queries
  # ===================

  def test_select_specific_columns
    results = Article.where(status: "published")
      .select(:id, :title_translations)
      .to_a

    assert_equal(2, results.size)
    assert_equal("Hello World", results.find { |a| a.id == @article1.id }.title)
  end

  def test_distinct_results
    results = Article.joins(:tags)
      .where(status: "published")
      .distinct
      .to_a

    assert_equal(1, results.count { |a| a.id == @article1.id })
  end

  def test_group_and_count
    counts = Article.group(:status).count

    assert_equal(2, counts["published"])
    assert_equal(1, counts["draft"])
  end

  def test_pluck_with_translations
    titles = Article.where(status: "published")
      .pluck(:title_translations)

    assert_equal(2, titles.size)
    assert(titles.all?(Hash))
  end
end
