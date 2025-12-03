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
| `i18n_where(**conditions, locale: nil, match: :exact)` | Query by translation (short alias) |
| `international_where(**conditions, locale: nil, match: :exact)` | Query by translation |
| `international_not(**conditions, locale: nil)` | Exclude matching records |
| `international_order(attr, dir = :asc, locale: nil)` | Order by translation |
| `translated(*attrs, locale: nil)` | Find records with translation |
| `untranslated(*attrs, locale: nil)` | Find records missing translation |

```ruby
# Examples
Article.i18n_where(title: "Hello World")
Article.i18n_where(title: "hello", match: :partial)  # case-insensitive LIKE
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

## Validations

For most validations, use standard Rails validators—they work with the virtual accessor:

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  international :title

  # Standard Rails validations (recommended)
  validates :title, presence: true
  validates :title, length: { minimum: 3, maximum: 100 }
  validates :title, format: { with: /\A[a-z]+\z/ }
end
```

Use `validates_international` only for uniqueness or multi-locale presence:

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  international :title

  # Uniqueness per-locale (requires JSON column querying)
  validates_international :title, uniqueness: true

  # Multi-locale presence (for admin interfaces editing all translations at once)
  validates_international :title, presence: { locales: [:en, :de] }
end
```

### Validation Options

| Option | Description |
|--------|-------------|
| `uniqueness: true` | Validates uniqueness per-locale (current locale) |
| `presence: { locales: [:en, :de] }` | Requires translations for specific locales |

### Error Keys

Both standard Rails validations and `validates_international` add errors to the base attribute for clean user-facing messages:

```ruby
article.errors[:title]  # => ["has already been taken"]
# Displays as: "Title has already been taken" (not "Title en has already been taken")
```

#### Locale-Specific Error Messages

For admin interfaces where you need to indicate which specific locale failed, use custom validations that add errors to locale-suffixed attributes:

```ruby
validate :validate_required_translations

private

def validate_required_translations
  [:en, :de].each do |locale|
    if send("title_#{locale}").blank?
      errors.add("title_#{locale}", :blank)
    end
  end
end
```

When using locale-suffixed error keys, configure Rails I18n for user-friendly display:

```yaml
# config/locales/en.yml
en:
  activerecord:
    attributes:
      article:
        title_en: "Title (English)"
        title_de: "Title (German)"
```

This displays as "Title (German) can't be blank" instead of "Title de can't be blank".

## ActionText Support

For rich text with attachments, include `Internationalize::RichText` and use `international_rich_text`:

```ruby
class Article < ApplicationRecord
  include Internationalize::Model
  include Internationalize::RichText  # Requires ActionText

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
