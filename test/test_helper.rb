# frozen_string_literal: true

# Start SimpleCov before loading any code
require "simplecov"
SimpleCov.start do
  add_filter "/test/"
  add_filter "/lib/generators/" # Requires Rails generators
  enable_coverage :branch

  # 100% line coverage required
  # 87% branch coverage to account for database adapter-specific branches
  # that require actual PostgreSQL/MySQL to cover
  minimum_coverage line: 100, branch: 87
end

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "minitest/autorun"
require "active_record"
require "i18n"
require "internationalize"

# Set up I18n
I18n.available_locales = [:en, :de, :fr, :es, :ja]
I18n.default_locale = :en
I18n.locale = :en

# Database configuration based on environment
DATABASE_ADAPTER = ENV.fetch("DATABASE_ADAPTER", "sqlite")

case DATABASE_ADAPTER
when "postgresql", "postgres"
  require "pg"
  database_name = ENV.fetch("DATABASE_NAME", "internationalize_test")

  ActiveRecord::Base.establish_connection(
    adapter: "postgresql",
    database: database_name,
    host: ENV.fetch("DATABASE_HOST", "localhost"),
    username: ENV.fetch("DATABASE_USER", ENV["USER"]),
    password: ENV.fetch("DATABASE_PASSWORD", nil),
  )

  puts "Using PostgreSQL database: #{database_name}"
  JSON_TYPE = :jsonb
else
  require "sqlite3"
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:",
  )

  puts "Using SQLite in-memory database"
  JSON_TYPE = :json
end

# Create test tables
ActiveRecord::Schema.define do
  create_table :articles, force: true do |t|
    t.column(:title_translations, JSON_TYPE, default: {})
    t.column(:description_translations, JSON_TYPE, default: {})
    t.string(:status)
    t.boolean(:published, default: false)
    t.references(:author, foreign_key: false)
    t.timestamps
  end

  create_table :products, force: true do |t|
    t.column(:name_translations, JSON_TYPE, default: {})
    t.decimal(:price)
    t.references(:category, foreign_key: false)
    t.timestamps
  end

  create_table :authors, force: true do |t|
    t.column(:name_translations, JSON_TYPE, default: {})
    t.column(:bio_translations, JSON_TYPE, default: {})
    t.string(:email)
    t.timestamps
  end

  create_table :categories, force: true do |t|
    t.column(:name_translations, JSON_TYPE, default: {})
    t.references(:parent, foreign_key: false)
    t.timestamps
  end

  create_table :comments, force: true do |t|
    t.column(:body_translations, JSON_TYPE, default: {})
    t.references(:article, foreign_key: false)
    t.references(:author, foreign_key: false)
    t.timestamps
  end

  create_table :tags, force: true do |t|
    t.column(:name_translations, JSON_TYPE, default: {})
    t.timestamps
  end

  create_table :article_tags, force: true do |t|
    t.references(:article, foreign_key: false)
    t.references(:tag, foreign_key: false)
  end

  # Integration test tables
  create_table :blogs, force: true do |t|
    t.json(:title_translations, default: {})
    t.json(:body_translations, default: {})
    t.string(:author)
    t.boolean(:published, default: false)
    t.timestamps
  end
end

# Blog model for integration tests
class Blog < ActiveRecord::Base
  include Internationalize::Model

  international :title, :body
end

# Test models with associations
class Author < ActiveRecord::Base
  include Internationalize::Model

  international :name, :bio

  has_many :articles
  has_many :comments
end

class Category < ActiveRecord::Base
  include Internationalize::Model

  international :name

  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id
  has_many :products
end

class Article < ActiveRecord::Base
  include Internationalize::Model

  international :title, :description

  belongs_to :author, optional: true
  has_many :comments, dependent: :destroy
  has_and_belongs_to_many :tags, join_table: :article_tags
end

class Product < ActiveRecord::Base
  include Internationalize::Model

  international :name, fallback: false

  belongs_to :category, optional: true
end

class Comment < ActiveRecord::Base
  include Internationalize::Model

  international :body

  belongs_to :article
  belongs_to :author, optional: true
end

class Tag < ActiveRecord::Base
  include Internationalize::Model

  international :name

  has_and_belongs_to_many :articles, join_table: :article_tags
end

# Base test class
class InternationalizeTestCase < Minitest::Test
  def setup
    I18n.locale = :en
    [Article, Product, Author, Category, Comment, Tag, Blog].each(&:delete_all)
    ActiveRecord::Base.connection.execute("DELETE FROM article_tags")
  end
end

# Helper to get current adapter name
def current_adapter_name
  ActiveRecord::Base.connection.adapter_name.downcase
end
