# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `validates_international` method for locale-specific validations:
  - `uniqueness: true` - validates uniqueness per-locale (requires JSON column querying)
  - `presence: { locales: [:en, :de] }` - requires translations for specific locales (useful for admin interfaces)
- Standard Rails validations (`validates :title, presence: true`) now work with virtual accessors

## [0.2.4] - 2024-11-29

### Added

- Fixtures documentation and tests demonstrating YAML format for translation columns

## [0.2.3] - 2024-11-29

### Added

- Auto-load RichText via Rails Railtie (fixes load order issue)

## [0.2.2] - 2024-11-29

### Added

- Validation for hyphenated locales (e.g., `zh-TW`) - raises helpful error suggesting underscore format (`zh_TW`)
- Auto-load `Internationalize::RichText` when ActionText is available (no manual require needed)

## [0.2.1] - 2024-11-29

### Added

- ActionText documentation in agent context files

## [0.2.0] - 2024-11-29

### Added

- ActionText support via `international_rich_text` (optional, requires ActionText)
  - Generates `has_rich_text` for each locale with unified accessor
  - Full attachment support per locale
- Validation for `title_translations=` setter - rejects non-Hash values and invalid locales

### Removed

- `fallback: false` option - translations now always fallback to default locale
- `set_translation(attr, locale, value)` - use `title_de = "value"` instead
- `translation_for(attr, locale)` - use `title_de` instead

## [0.1.1] - 2024-11-29

### Fixed

- Include `context/` directory in gem for `bake agent:context:install` support

## [0.1.0] - 2024-11-29

### Added

- Initial release
- `Internationalize::Model` mixin for ActiveRecord models
- `international` declaration for translatable attributes
- Locale-specific accessors (`title_en`, `title_de`, etc.)
- Query methods:
  - `international(attr: value)` - exact match queries
  - `international(attr: value, match: :partial)` - case-insensitive LIKE search
  - `international_not()` - exclusion queries
  - `international_order()` - order by translated attribute
  - `translated()` - find records with translations
  - `untranslated()` - find records missing translations
- Creation helpers:
  - `international_create!` / `international_create` / `international_new`
  - Support both hash format `title: { en: "Hello" }` and direct string `title: "Hello"` (uses current locale)
- Instance helpers:
  - `set_translation(attr, locale, value)`
  - `translation_for(attr, locale)`
  - `translated?(attr, locale)`
  - `translated_locales(attr)`
- Fallback to default locale when translation missing
- SQLite adapter using `json_extract()`
- PostgreSQL adapter using `->>` operator
- MySQL 8+ adapter using `->>` operator (supports mysql2 and trilogy gems)
- Rails generator: `rails g internationalize:translation Model attr1 attr2`
- Warning when JSON columns are missing `default: {}`
- Security: locale parameter sanitization to prevent SQL injection
