# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake"
  gem "bake"
  gem "agent-context"
  gem "minitest", "~> 5.20"
  gem "simplecov", require: false
  gem "sqlite3", ">= 1.6"
  gem "pg", "~> 1.5"
  gem "railties", ">= 7.0" # For generator tests
  gem "rubocop-shopify", "~> 2.18"
  gem "rubocop-performance", "~> 1.23"
  gem "mobility", "~> 1.3", require: false # For benchmarks only
  gem "benchmark" # Will be removed from stdlib in Ruby 3.5
  gem "stackprof"
end
