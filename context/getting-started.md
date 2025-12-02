# Internationalize: Getting Started

Internationalize is a lightweight internationalization gem for Rails that stores translations in JSON columns instead of separate tables.

## Installation

```ruby
# Gemfile
gem "internationalize"
```

## Quick Setup

### 1. Generate a migration for translation columns

```bash
rails generate internationalize:translation Article title description
```

This creates a migration adding `title_translations` and `description_translations` JSON columns.

Or write the migration manually:

```ruby
class AddTranslationsToArticles < ActiveRecord::Migration[7.1]
  def change
    add_column :articles, :title_translations, :json, default: {}
    add_column :articles, :description_translations, :json, default: {}
  end
end
```

### 2. Include the mixin and declare translatable attributes

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  international :title, :description
end
```

### 3. Use translations

```ruby
# Create with translations (hash for multiple locales)
Article.international_create!(
  title: { en: "Hello World", de: "Hallo Welt" },
  status: "published"
)

# Or direct string for current locale
I18n.locale = :de
Article.international_create!(title: "Achtung!")  # Sets title_de

# Set translation for current locale
article.title = "Hello World"

# Set for specific locale
article.title_en = "Hello World"
article.title_de = "Hallo Welt"

# Read translation
article.title         # => uses I18n.locale
article.title_de      # => "Hallo Welt"

# Access raw hash
article.title_translations  # => {"en" => "Hello World", "de" => "Hallo Welt"}
```

### 4. Query translations

```ruby
# Exact match
Article.i18n_where(title: "Hello World")

# Partial match (LIKE)
Article.i18n_where(title: "Hello", match: :partial)

# Order by translation
Article.international_order(:title, :desc)
```

## Key Concepts

- Translations stored in `*_translations` JSON columns
- No JOINs - data lives in the same table
- Automatic fallback to default locale
- Works with SQLite, PostgreSQL, and MySQL
- ActionText support via `international_rich_text` (see Model API)

## Important: Column Defaults

JSON columns **must** have `default: {}` set in the migration. The generator does this automatically, but if writing migrations manually, ensure you include it:

```ruby
add_column :articles, :title_translations, :json, default: {}
```

This is required for optimal performance and correct behavior.
