# Internationalize: Configuration

## Zero Configuration

No configuration required. Internationalize uses your existing Rails I18n settings:

- `I18n.available_locales` - determines which locale accessors are generated
- `I18n.default_locale` - used for fallback when translation is missing

## Override Locales (Rarely Needed)

```ruby
# config/initializers/internationalize.rb
Internationalize.configure do |config|
  config.available_locales = [:en, :de, :fr, :es]
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

Internationalize uses Rails I18n settings directly:

```ruby
I18n.locale           # Used for current locale
I18n.default_locale   # Used for fallbacks
I18n.available_locales # Used for locale-specific accessors (can be overridden)
```
