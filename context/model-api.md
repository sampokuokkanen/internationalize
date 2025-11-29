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
| `title_translations=` | Set all translations at once (validates locale keys) |

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

## ActionText Support

For rich text with attachments, use `international_rich_text` (auto-loaded when ActionText is available):

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  include Internationalize::RichText

  international_rich_text :content
end
```

This generates `has_rich_text :content_en`, `has_rich_text :content_de`, etc. for each locale.

### Generated Methods

| Method | Description |
|--------|-------------|
| `content` | Get rich text for current locale (with fallback) |
| `content=` | Set rich text for current locale |
| `content?` | Check if rich text exists |
| `content_en` | Direct access to English rich text |
| `content_de` | Direct access to German rich text |
| `content_translated?(:de)` | Check if translation exists |
| `content_translated_locales` | Array of locales with content |

```ruby
article.content = "<p>Hello</p>"  # Sets for current locale
article.content                    # Gets for current locale (with fallback)
article.content.body               # ActionText::Content object
article.content.embeds             # Attachments work per-locale
```

## Fixtures

Use the actual column name (`*_translations`) in fixtures, not the virtual accessor:

### Nested Format

```yaml
# test/fixtures/articles.yml
hello_world:
  title_translations:
    en: "Hello World"
    de: "Hallo Welt"
  description_translations:
    en: "A greeting"
    de: "Eine Begrüßung"
  status: published
```

### Inline Hash Format

```yaml
japanese_post:
  title_translations: { en: "Hello", ja: "こんにちは" }
  status: published
```

### Important Notes

- Use `title_translations:` (column name), NOT `title:`
- Keys can be symbols (`:en`) or strings (`"en"`) - YAML converts them
- Both nested and inline hash formats work identically
- Missing locales are simply not set (no error)
