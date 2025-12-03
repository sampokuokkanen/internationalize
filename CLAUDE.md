# Internationalize - Development Context

This file provides context for AI assistants working on this codebase.

## Project Overview

Internationalize is a Rails gem for storing translations in JSON columns. It supports SQLite, PostgreSQL, and MySQL.

## Key Files

- `lib/internationalize/model.rb` - Main model mixin, defines `international` DSL
- `lib/internationalize/validations.rb` - Validation helpers (`validates_international`)
- `lib/internationalize/adapters/` - Database-specific SQL generation
- `lib/internationalize/rich_text.rb` - ActionText support

## Validation Behavior

### Error Messages Use Base Attribute Names

`validates_international` adds errors to the **base attribute** (e.g., `:title`), not the locale-suffixed attribute (e.g., `:title_en`). This ensures clean user-facing messages:

```ruby
# Good: "Title has already been taken"
# Bad:  "Title en has already been taken"
```

### Why This Matters

When Rails displays validation errors, it humanizes the attribute name. Adding errors to `title_en` would display as "Title en" which exposes internal implementation details to users.

### Locale-Specific Errors for Admin Interfaces

For admin interfaces editing multiple locales simultaneously where you need to know which specific locale failed, users should write custom validations that add errors to locale-suffixed attributes:

```ruby
validate :validate_required_translations

def validate_required_translations
  [:en, :de].each do |locale|
    if send("title_#{locale}").blank?
      errors.add("title_#{locale}", :blank)
    end
  end
end
```

When using locale-suffixed error keys, configure Rails I18n attribute names for user-friendly display:

```yaml
en:
  activerecord:
    attributes:
      article:
        title_en: "Title (English)"
        title_de: "Title (German)"
```

This displays as "Title (German) can't be blank" instead of "Title de can't be blank".

## Testing

Run tests with: `bundle exec rake test`

The test suite uses SQLite in-memory database by default. Tests for PostgreSQL and MySQL adapters use mocking.

## Common Patterns

### Query Methods

- `i18n_where` / `international_where` - Exact/partial match queries
- `international_not` - Exclude matches
- `international_order` - Order by translated field
- `translated` / `untranslated` - Find records with/without translations

The old `international` query method is deprecated in favor of `i18n_where`.

### Accessor Methods

For an `international :title` declaration:
- `title` - Read/write for current `I18n.locale`
- `title_en`, `title_de`, etc. - Direct locale access
- `title_translations` - Raw JSON hash
