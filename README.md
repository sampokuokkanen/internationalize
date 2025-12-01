# Internationalize

[![Gem Version](https://badge.fury.io/rb/internationalize.svg)](https://rubygems.org/gems/internationalize)
[![Build](https://github.com/sampokuokkanen/internationalize/workflows/CI/badge.svg)](https://github.com/sampokuokkanen/internationalize/actions)

Lightweight, performant internationalization for Rails with JSON column storage.

## Why Internationalize?

Internationalize is a focused, lightweight gem that does one thing well: JSON column translations. No backend abstraction layers, no plugin systems, no extra memory overhead.

Unlike Globalize (separate translation tables) or Mobility (JSON backend is PostgreSQL-only), Internationalize stores translations inline using JSON columns with **full SQLite, PostgreSQL, and MySQL support**:

- **No JOINs** - translations live in the same table
- **No N+1 queries** - data is always loaded with the record
- **No backend overhead** - direct JSON column access, no abstraction layers
- **~50% less memory** - no per-instance backend objects or plugin chains
- **Direct method dispatch** - no `method_missing` overhead
- **True multi-database JSON support** - SQLite 3.38+, PostgreSQL 9.4+, MySQL 8.0+
- **ActionText support** - internationalized rich text with attachments
- **Visible in schema.rb** - translated fields appear directly in your model's schema

> **Note:** Mobility's JSON/JSONB backends only work with PostgreSQL. For SQLite or MySQL, Mobility requires separate translation tables with JOINs. Internationalize provides JSON column querying across all three databases.

## Supported Databases

| Database | JSON Column | Query Syntax |
|----------|-------------|--------------|
| SQLite 3.38+ | `json` | `json_extract()` |
| PostgreSQL 9.4+ | `json` / `jsonb` | `->>` operator |
| MySQL 8.0+ | `json` | `->>` operator |

## Installation

Add to your Gemfile:

```ruby
gem "internationalize"
```

## Usage

### 1. Generate a migration

```bash
rails generate internationalize:translation Article title description
```

This creates a migration adding `title_translations` and `description_translations` JSON columns with `default: {}`.

**Important:** JSON columns must have `default: {}` set. The generator handles this automatically, but if writing migrations manually:

```ruby
add_column :articles, :title_translations, :json, default: {}
```

### 2. Include the model mixin

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  international :title, :description
end
```

### 3. Use translations

```ruby
# Set via current locale (I18n.locale)
article.title = "Hello World"

# Set for specific locale
article.title_en = "Hello World"
article.title_de = "Hallo Welt"

# Read via current locale
article.title  # => "Hello World" (when I18n.locale == :en)

# Read specific locale
article.title_de  # => "Hallo Welt"

# Access raw translations
article.title_translations  # => {"en" => "Hello World", "de" => "Hallo Welt"}
```

### Creating Records

Use the helper methods for a cleaner syntax when creating records with translations:

```ruby
# Create with multiple locales using a hash
Article.international_create!(
  title: { en: "Hello World", de: "Hallo Welt" },
  description: { en: "A greeting" },
  status: "published"  # non-translated attributes work normally
)

# Or use direct assignment for current locale (I18n.locale)
I18n.locale = :de
Article.international_create!(title: "Achtung!")  # Sets title_de

# Mix both styles
Article.international_create!(
  title: "Hello",  # Current locale only
  description: { en: "English", de: "German" }  # Multiple locales
)

# Build without saving
article = Article.international_new(title: "Hello")
article.save!

# Non-bang version returns unsaved record on validation failure
article = Article.international_create(title: { en: "Hello" })
```

### Querying

All query methods default to the current `I18n.locale` and return ActiveRecord relations that can be chained with standard AR methods.

```ruby
# Exact match on translation (uses current locale by default)
Article.international(title: "Hello World")
Article.international(title: "Hallo Welt", locale: :de)

# Partial match / search (case-insensitive LIKE)
Article.international(title: "hello", match: :partial)
Article.international(title: "Hello", match: :partial, case_sensitive: true)
Article.international(title: "hallo", match: :partial, locale: :de)

# Exclude matches
Article.international_not(title: "Draft")
Article.international_not(title: "Entwurf", locale: :de)

# Order by translation
Article.international_order(:title)
Article.international_order(:title, :desc)
Article.international_order(:title, :asc, locale: :de)

# Find translated/untranslated records
Article.translated(:title)
Article.translated(:title, locale: :de)
Article.untranslated(:title, locale: :de)

# Chain with ActiveRecord methods
Article.international(title: "Hello World")
       .where(published: true)
       .includes(:author)
       .limit(10)

# Combine queries
Article.international(title: "hello", match: :partial)
       .where(status: "published")
       .merge(Article.international_order(:title, :desc))

# Query across multiple locales
Article.international(title: "Hello World", locale: :en)
       .merge(Article.international(title: "Hallo Welt", locale: :de))
```

### Helper Methods

```ruby
# Check if translation exists
article.translated?(:title, :de)  # => true/false

# Get all translated locales for an attribute
article.translated_locales(:title)  # => [:en, :de]
```

### Fallbacks

By default, Internationalize falls back to the default locale when a translation is missing:

```ruby
article.title_en = "Hello"
article.title_de  # => nil

I18n.locale = :de
article.title  # => "Hello" (falls back to :en)
```

### ActionText Support

For rich text with attachments (requires ActionText):

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  include Internationalize::RichText

  international_rich_text :content
end
```

This generates `has_rich_text :content_en`, `has_rich_text :content_de`, etc. for each locale, with a unified accessor:

```ruby
article.content = "<p>Hello</p>"     # Sets for current locale
article.content                       # Gets for current locale (with fallback)
article.content_en                    # Direct access to English
article.content.body                  # ActionText::Content object
article.content.embeds                # Attachments work per-locale
```

### Fixtures

Use the `*_translations` column name with nested locale keys:

```yaml
# test/fixtures/articles.yml
hello_world:
  title_translations:
    en: "Hello World"
    de: "Hallo Welt"
  status: published
```

## Configuration

```ruby
# config/initializers/internationalize.rb
Internationalize.configure do |config|
  config.available_locales = [:en, :de, :fr]  # Defaults to I18n.available_locales
end
```

Fallback uses `I18n.default_locale` automatically.

## Performance Comparison

Benchmark with 1000 records, 2 translated attributes (title + body), 3 locales:

| Metric | Internationalize | Mobility (Table) | Improvement |
|--------|------------------|------------------|-------------|
| Storage | 172 KB | 332 KB | **48% smaller** |
| Create | 0.27s | 2.1s | **7.8x faster** |
| Read all | 0.005s | 0.37s | **74x faster** |
| Query (match) | 0.001s | 0.01s | **10x faster** |

## Trade-offs

### Pros
- **Faster reads** - No JOINs needed, translations are inline
- **Less storage** - No separate translation tables with foreign keys and indices
- **Simpler schema** - Everything in one table

### Cons
- **Schema changes required** - Each translated attribute needs a JSON column added to the table
- **Migration complexity** - Adding translations to existing tables requires data migration
- **JSON column support** - Requires SQLite 3.38+, PostgreSQL 9.4+, or MySQL 8.0+

### When to use Internationalize
- New projects where you can design the schema upfront
- Applications with heavy read workloads
- When you need maximum query performance

### When to consider Mobility

Consider [Mobility](https://github.com/shioyama/mobility) if:

- You need to add translations without modifying existing table schemas
- You're on PostgreSQL and want their JSON backend (note: PostgreSQL-only)
- You need the flexibility of multiple backend strategies

Mobility's table backend stores translations in separate tables with JOINs, which trades query performance for schema flexibility. Their JSON backend is PostgreSQL-only.

## License

MIT License. See LICENSE.txt.
