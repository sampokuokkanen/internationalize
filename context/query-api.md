# Internationalize: Query API

All query methods are class methods on models that include `Internationalize::Model`. They return `ActiveRecord::Relation` objects that can be chained with standard AR methods.

## Default Locale Behavior

All query methods default to the current `I18n.locale`. Use the `locale:` option to override:

```ruby
# Uses current I18n.locale
Article.international(title: "Hello World")

# Explicit locale
Article.international(title: "Hallo Welt", locale: :de)
```

## Query Methods

### international(**conditions, locale: nil)

Exact match on translated attributes:

```ruby
Article.international(title: "Hello World")
Article.international(title: "Hello", status: "published")
Article.international(title: "Hallo Welt", locale: :de)
```

### international_not(**conditions, locale: nil)

Exclude records matching conditions:

```ruby
Article.international_not(title: "Draft")
Article.international_not(title: "Entwurf", locale: :de)
```

### international_search(**conditions, locale: nil, case_sensitive: false)

Substring search (LIKE/ILIKE):

```ruby
# Case-insensitive (default)
Article.international_search(title: "hello")
Article.international_search(title: "hello", description: "world")

# Case-sensitive
Article.international_search(title: "Hello", case_sensitive: true)

# With explicit locale
Article.international_search(title: "welt", locale: :de)
```

### international_order(attribute, direction = :asc, locale: nil)

Order by translated attribute:

```ruby
Article.international_order(:title)
Article.international_order(:title, :desc)
Article.international_order(:title, :asc, locale: :de)
```

### translated(*attributes, locale: nil)

Find records with translations in specified locale:

```ruby
Article.translated(:title)
Article.translated(:title, locale: :de)
Article.translated(:title, :description, locale: :de)
```

### untranslated(*attributes, locale: nil)

Find records missing translations:

```ruby
Article.untranslated(:title)
Article.untranslated(:title, locale: :de)
```

## Chaining with ActiveRecord

All methods return `ActiveRecord::Relation`, so they chain naturally with AR methods:

```ruby
Article.international(title: "Hello World")
       .where(published: true)
       .order(created_at: :desc)
       .limit(10)
       .includes(:author)
```

## Combining Multiple Queries

Use `merge` to combine multiple international queries:

```ruby
# Search + filter + order
Article.international_search(title: "hello")
       .merge(Article.international(status: "published"))
       .merge(Article.international_order(:title, :desc))

# Query across multiple locales
Article.international(title: "Hello World", locale: :en)
       .merge(Article.international(title: "Hallo Welt", locale: :de))
```

## Examples

```ruby
# Find published articles with German title containing "Welt"
Article.international_search(title: "Welt", locale: :de)
       .where(published: true)
       .merge(Article.international_order(:title, locale: :de))
       .limit(10)

# Find articles missing German translation
Article.untranslated(:title, locale: :de).count

# Complex multi-locale query - find articles with both EN and DE titles
Article.translated(:title, locale: :en)
       .merge(Article.translated(:title, locale: :de))

# Exclude drafts and order by title
Article.international_not(status: "draft")
       .merge(Article.international_order(:title))
```
