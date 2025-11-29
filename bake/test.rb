# frozen_string_literal: true

# Run all tests against SQLite (default)
def sqlite
  system("ruby", "-I", "lib:test", "-e", <<~RUBY)
    ENV['DATABASE_ADAPTER'] = 'sqlite'
    require 'test_helper'
    Dir['test/*_test.rb'].each { |f| require f.sub('test/', '') }
  RUBY
end

# Run all tests against PostgreSQL
# @parameter database [String] PostgreSQL database name (default: internationalize_test)
def postgresql(database: "internationalize_test")
  system("ruby", "-I", "lib:test", "-e", <<~RUBY)
    ENV['DATABASE_ADAPTER'] = 'postgresql'
    ENV['DATABASE_NAME'] = '#{database}'
    require 'test_helper'
    Dir['test/*_test.rb'].each { |f| require f.sub('test/', '') }
  RUBY
end

# Run all tests against all supported databases
# @parameter database [String] PostgreSQL database name (default: internationalize_test)
def all(database: "internationalize_test")
  puts "=" * 60
  puts "Running tests with SQLite..."
  puts "=" * 60
  sqlite_result = sqlite

  puts "\n" + "=" * 60
  puts "Running tests with PostgreSQL..."
  puts "=" * 60
  pg_result = postgresql(database: database)

  if sqlite_result && pg_result
    puts "\n✓ All tests passed on both databases!"
  else
    puts "\n✗ Some tests failed"
    exit(1)
  end
end
