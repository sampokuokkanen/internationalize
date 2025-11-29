# frozen_string_literal: true

require_relative "lib/internationalize/version"

Gem::Specification.new do |spec|
  spec.name = "internationalize"
  spec.version = Internationalize::VERSION
  spec.authors = ["Sampo Kuokkanen"]
  spec.email = ["sampo.kuokkanen@gmail.com"]

  spec.summary = "Lightweight, performant i18n for Rails with JSON column storage"
  spec.description = "Zero-config internationalization for ActiveRecord models using JSON columns. " \
    "No JOINs, no N+1 queries, just fast inline translations. " \
    "Supports SQLite, PostgreSQL, and MySQL."
  spec.homepage = "https://github.com/sampokuokkanen/internationalize"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(__dir__) do
    Dir["{lib}/**/*", "LICENSE.txt", "README.md", "CHANGELOG.md"]
  end
  spec.require_paths = ["lib"]

  spec.add_dependency("activerecord", ">= 7.0")
  spec.add_dependency("activesupport", ">= 7.0")
end
