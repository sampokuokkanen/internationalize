# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-11-28

### Added

- Initial release
- `Internationalize::Model` mixin for ActiveRecord models
- `international` declaration for translatable attributes
- Locale-specific accessors (`title_en`, `title_de`, etc.)
- Query methods:
  - `international()` - exact match queries
  - `international_search()` - case-insensitive substring search
  - `international_not()` - exclusion queries
  - `international_order()` - order by translated attribute
  - `translated()` - find records with translations
  - `untranslated()` - find records missing translations
- Fallback to default locale when translation missing
- SQLite adapter using `json_extract()`
- PostgreSQL adapter using `->>` operator
- MySQL 8+ adapter using `->>` operator (supports mysql2 and trilogy gems)
- Rails generator for translation migrations
- Security: locale parameter sanitization to prevent SQL injection
