# Internationalize: Configuration

## Global Configuration

```ruby
# config/initializers/internationalize.rb
Internationalize.configure do |config|
  # Override fallback locale (defaults to I18n.default_locale)
  config.fallback_locale = :en

  # Override available locales (defaults to I18n.available_locales)
  config.available_locales = [:en, :de, :fr, :es]
end
```

## Per-Attribute Configuration

```ruby
class Article < ApplicationRecord
  include Internationalize::Model

  # With fallback (default)
  international :title

  # Without fallback
  international :description, fallback: false
end
```

## Database Setup

Use the generator to create migrations:

```bash
rails generate internationalize:translation Article title description
```

Or create migrations manually:

### SQLite / MySQL

```ruby
class AddTranslationsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :title_translations, :json, default: {}
  end
end
```

### PostgreSQL

For better query performance, use `jsonb`:

```ruby
class AddTranslationsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :title_translations, :jsonb, default: {}

    # Optional: Add GIN index for faster queries
    add_index :articles, :title_translations, using: :gin
  end
end
```

## Supported Databases

| Database | Minimum Version | JSON Type | Query Syntax |
|----------|-----------------|-----------|--------------|
| SQLite | 3.38+ | `json` | `json_extract()` |
| PostgreSQL | 9.4+ | `json`/`jsonb` | `->>` operator |
| MySQL | 8.0+ | `json` | `->>` operator |

## I18n Integration

Internationalize automatically uses Rails I18n settings:

```ruby
I18n.locale           # Used for current locale
I18n.default_locale   # Used for fallbacks
I18n.available_locales # Used for locale-specific accessors
```

Override these with the configuration options above if needed.
