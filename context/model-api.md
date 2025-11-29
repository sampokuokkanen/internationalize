# Internationalize: Model API

## Including the Mixin

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  international :title, :description
end
```

## Generated Instance Methods

For each `international :title` declaration:

### Accessors

| Method | Description |
|--------|-------------|
| `title` | Get translation for current `I18n.locale` |
| `title=` | Set translation for current `I18n.locale` |
| `title?` | Check if translation exists |
| `title_translations` | Get raw hash of all translations |
| `title_translations=` | Set all translations at once |

### Locale-Specific Accessors

For each locale in `I18n.available_locales`:

| Method | Description |
|--------|-------------|
| `title_en` | Get English translation directly |
| `title_en=` | Set English translation |
| `title_en?` | Check if English translation exists |
| `title_de` | Get German translation |
| `title_de=` | Set German translation |
| ... | etc. for all locales |

### Instance Helper Methods

| Method | Description |
|--------|-------------|
| `translated?(:title, :de)` | Check if translation exists |
| `translated_locales(:title)` | Array of locales with translations |

## Class Methods (Querying)

All query methods default to current `I18n.locale` and return `ActiveRecord::Relation`:

| Method | Description |
|--------|-------------|
| `international(**conditions, locale: nil)` | Exact match query |
| `international_not(**conditions, locale: nil)` | Exclude matching records |
| `international_search(**conditions, locale: nil, case_sensitive: false)` | Substring search |
| `international_order(attr, dir = :asc, locale: nil)` | Order by translation |
| `translated(*attrs, locale: nil)` | Find records with translation |
| `untranslated(*attrs, locale: nil)` | Find records missing translation |

```ruby
# Examples
Article.international(title: "Hello World")
Article.international_search(title: "hello", locale: :de)
Article.international_order(:title, :desc)
Article.translated(:title, locale: :de)
```

## Class Attributes

```ruby
Article.international_attributes  # => [:title, :description]
```

## Fallback Behavior

Translations automatically fall back to the default locale when missing:

```ruby
article.title_en = "Hello"
I18n.locale = :de
article.title  # => "Hello" (falls back to default locale)
```
