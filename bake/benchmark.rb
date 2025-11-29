# frozen_string_literal: true

require "benchmark"

# Run performance benchmarks comparing Internationalize with Mobility
# @parameter count [Integer] Number of records to create (default: 1000)
# @parameter adapter [String] Database adapter: sqlite or postgresql (default: sqlite)
def compare(count: 1000, adapter: "sqlite")
  setup_environment(adapter)

  require "active_record"
  require "i18n"
  require "internationalize"

  setup_database(adapter)
  setup_internationalize_model

  puts "=" * 70
  puts "Internationalize Performance Benchmark"
  puts "Database: #{adapter.upcase}"
  puts "Records: #{count}"
  puts "=" * 70

  # Check if Mobility is available
  mobility_available = begin
    require "mobility"
    true
  rescue LoadError
    false
  end

  puts ""
  internationalize_size = run_internationalize_benchmarks(count, adapter)

  puts ""
  if mobility_available
    puts "=" * 70
    puts "Mobility (Table Backend) Comparison"
    puts "=" * 70
    setup_mobility_table_model
    mobility_table_size = run_mobility_benchmarks(count, adapter, "table")

    puts ""
    puts "=" * 70
    puts "Mobility (JSON Backend) Comparison"
    puts "=" * 70
    setup_mobility_json_model(adapter)
    mobility_json_size = run_mobility_json_benchmarks(count, adapter)

    puts ""
    puts "=" * 70
    puts "Storage Size Comparison"
    puts "=" * 70
    puts "Internationalize:             #{format_size(internationalize_size)}"
    puts "Mobility (Table):     #{format_size(mobility_table_size)}"
    puts "Mobility (JSON):      #{format_size(mobility_json_size)}"
    if mobility_table_size > 0 && internationalize_size > 0
      puts ""
      puts "Internationalize uses #{(internationalize_size.to_f / mobility_table_size * 100).round(1)}% of Mobility Table storage"
      puts "Internationalize uses #{(internationalize_size.to_f / mobility_json_size * 100).round(1)}% of Mobility JSON storage"
    end
  else
    puts "Mobility gem not installed. Install with: gem install mobility"
    puts "Then run again to compare performance."
  end

  puts ""
  puts "=" * 70
end

# Run Internationalize benchmarks only
# @parameter count [Integer] Number of records to create (default: 1000)
# @parameter adapter [String] Database adapter: sqlite or postgresql (default: sqlite)
def internationalize(count: 1000, adapter: "sqlite")
  setup_environment(adapter)

  require "active_record"
  require "i18n"
  require "internationalize"

  setup_database(adapter)
  setup_internationalize_model

  puts "Internationalize Benchmark (#{adapter.upcase}, #{count} records)"
  puts "-" * 50

  run_internationalize_benchmarks(count, adapter)
end

# Run storage comparison only
# @parameter count [Integer] Number of records to create (default: 1000)
# @parameter adapter [String] Database adapter: sqlite or postgresql (default: sqlite)
def storage(count: 1000, adapter: "sqlite")
  setup_environment(adapter)

  require "active_record"
  require "i18n"
  require "internationalize"

  setup_database(adapter)

  mobility_available = begin
    require "mobility"
    true
  rescue LoadError
    false
  end

  puts "=" * 70
  puts "Storage Size Comparison"
  puts "Database: #{adapter.upcase}"
  puts "Records: #{count}"
  puts "=" * 70

  # Create Internationalize records
  setup_internationalize_model
  BenchmarkPost.delete_all
  count.times do |i|
    BenchmarkPost.create!(
      title_translations: { "en" => "Title #{i}", "de" => "Titel #{i}", "fr" => "Titre #{i}" },
      body_translations: { "en" => "Body content #{i}", "de" => "Inhalt #{i}" },
      status: i.even? ? "published" : "draft",
    )
  end
  internationalize_size = measure_storage("benchmark_posts", adapter)
  puts "Internationalize:             #{format_size(internationalize_size)}"

  if mobility_available
    # Create Mobility Table records
    setup_mobility_table_model
    MobilityPost.delete_all
    count.times do |i|
      post = MobilityPost.new(status: i.even? ? "published" : "draft")
      I18n.with_locale(:en) do
        post.title = "Title #{i}"
        post.body = "Body content #{i}"
      end
      I18n.with_locale(:de) do
        post.title = "Titel #{i}"
        post.body = "Inhalt #{i}"
      end
      I18n.with_locale(:fr) { post.title = "Titre #{i}" }
      post.save!
    end
    mobility_table_size = measure_mobility_table_storage(adapter)
    puts "Mobility (Table):     #{format_size(mobility_table_size)}"

    # Create Mobility JSON records
    mobility_json_size = 0
    begin
      setup_mobility_json_model(adapter)
      MobilityJsonPost.delete_all
      count.times do |i|
        post = MobilityJsonPost.new(status: i.even? ? "published" : "draft", title: {}, body: {})
        I18n.with_locale(:en) do
          post.title = "Title #{i}"
          post.body = "Body content #{i}"
        end
        I18n.with_locale(:de) do
          post.title = "Titel #{i}"
          post.body = "Inhalt #{i}"
        end
        I18n.with_locale(:fr) { post.title = "Titre #{i}" }
        post.save!
      end
      mobility_json_size = measure_storage("mobility_json_posts", adapter)
      puts "Mobility (JSON):      #{format_size(mobility_json_size)}"
    rescue StandardError => e
      puts "Mobility (JSON):      Error - #{e.message.split("\n").first}"
    end

    puts ""
    if mobility_table_size > 0
      ratio = (internationalize_size.to_f / mobility_table_size * 100).round(1)
      puts "Internationalize uses #{ratio}% of Mobility Table storage (#{(100 - ratio).round(1)}% smaller)"
    end
    if mobility_json_size > 0
      ratio = (internationalize_size.to_f / mobility_json_size * 100).round(1)
      puts "Internationalize uses #{ratio}% of Mobility JSON storage (#{(100 - ratio).round(1)}% smaller)"
    end
  else
    puts ""
    puts "Mobility gem not installed. Install with: gem install mobility"
  end
end

def setup_environment(adapter)
  ENV["DATABASE_ADAPTER"] = adapter
end

def setup_database(adapter)
  I18n.available_locales = [:en, :de, :fr, :es, :it]
  I18n.default_locale = :en

  json_type = case adapter
  when "postgresql", "postgres"
    require "pg"
    ActiveRecord::Base.establish_connection(
      adapter: "postgresql",
      database: "internationalize_test",
    )
    :jsonb
  else
    require "sqlite3"
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: "benchmark_test.db",
    )
    :json
  end

  ActiveRecord::Schema.define do
    create_table(:benchmark_posts, force: true) do |t|
      t.column(:title_translations, json_type)
      t.column(:body_translations, json_type)
      t.string(:status)
      t.timestamps
    end

    create_table(:mobility_posts, force: true) do |t|
      t.string(:status)
      t.timestamps
    end

    create_table(:mobility_json_posts, force: true) do |t|
      t.column(:title, json_type, default: {})
      t.column(:body, json_type, default: {})
      t.string(:status)
      t.timestamps
    end

    # Mobility table backend - model-specific translation table
    create_table(:mobility_post_translations, force: true) do |t|
      t.string(:locale, null: false)
      t.references(:mobility_post, null: false, foreign_key: false, index: true)
      t.string(:title)
      t.text(:body)
      t.timestamps(null: false)
    end

    add_index(:mobility_post_translations, [:mobility_post_id, :locale], unique: true, name: "index_mobility_post_translations_on_post_and_locale")

    # Mobility polymorphic translation tables (alternative backend)
    create_table(:mobility_string_translations, force: true) do |t|
      t.string(:locale, null: false)
      t.string(:key, null: false)
      t.string(:value)
      t.references(:translatable, polymorphic: true, index: false)
      t.timestamps(null: false)
    end

    create_table(:mobility_text_translations, force: true) do |t|
      t.string(:locale, null: false)
      t.string(:key, null: false)
      t.text(:value)
      t.references(:translatable, polymorphic: true, index: false)
      t.timestamps(null: false)
    end
  end
end

def setup_internationalize_model
  Object.send(:remove_const, :BenchmarkPost) if defined?(BenchmarkPost)

  # Use eval to create a named class (anonymous classes don't work with newer ActiveRecord)
  eval(<<-RUBY, TOPLEVEL_BINDING, __FILE__, __LINE__ + 1)
    class BenchmarkPost < ActiveRecord::Base
      include Internationalize::Model
      international :title, :body
    end
  RUBY
end

def configure_mobility
  return if @mobility_configured

  Mobility.configure do
    plugins do
      backend
      active_record
      reader
      writer
      query
    end
  end
  @mobility_configured = true
end

def setup_mobility_table_model
  configure_mobility

  # Define class with proper name using eval to avoid anonymous class issues
  unless defined?(MobilityPost)
    eval(<<-RUBY, TOPLEVEL_BINDING, __FILE__, __LINE__ + 1)
      class MobilityPost < ActiveRecord::Base
        extend Mobility
        translates :title, backend: :table
        translates :body, backend: :table
      end
    RUBY
  end
end

def setup_mobility_json_model(adapter)
  configure_mobility

  backend = adapter.include?("postgres") ? :jsonb : :json

  # Define class with proper name
  unless defined?(MobilityJsonPost)
    # rubocop:disable Security/Eval -- Dynamic class definition for benchmark comparison
    eval(<<-RUBY, TOPLEVEL_BINDING, __FILE__, __LINE__ + 1)
      class MobilityJsonPost < ActiveRecord::Base
        extend Mobility
        translates :title, backend: :#{backend}
        translates :body, backend: :#{backend}
      end
    RUBY
    # rubocop:enable Security/Eval
  end
end

def measure_storage(table_name, adapter)
  result = case adapter
  when "postgresql", "postgres"
    ActiveRecord::Base.connection.execute(
      "SELECT pg_total_relation_size('#{table_name}') as size",
    )
  else
    # For SQLite, get page count * page size
    ActiveRecord::Base.connection.execute(
      "SELECT SUM(pgsize) as size FROM dbstat WHERE name = '#{table_name}'",
    )
  end
  result.first["size"].to_i
rescue StandardError
  0
end

def measure_mobility_table_storage(adapter)
  main_table = measure_storage("mobility_posts", adapter)
  translations = measure_storage("mobility_post_translations", adapter)
  main_table + translations
end

def format_size(bytes)
  return "N/A" if bytes.nil? || bytes == 0

  if bytes < 1024
    "#{bytes} B"
  elsif bytes < 1024 * 1024
    "#{(bytes / 1024.0).round(2)} KB"
  else
    "#{(bytes / (1024.0 * 1024)).round(2)} MB"
  end
end

def run_internationalize_benchmarks(count, adapter)
  BenchmarkPost.delete_all

  puts "Internationalize Results:"
  puts ""

  Benchmark.bm(25) do |x|
    # Write benchmark
    x.report("Create #{count} records:") do
      count.times do |i|
        BenchmarkPost.create!(
          title_translations: {
            "en" => "Title #{i}",
            "de" => "Titel #{i}",
            "fr" => "Titre #{i}",
          },
          body_translations: {
            "en" => "Body content #{i}",
            "de" => "Inhalt #{i}",
          },
          status: i.even? ? "published" : "draft",
        )
      end
    end

    # Read benchmarks
    x.report("Read all (current locale):") do
      BenchmarkPost.all.each(&:title)
    end

    x.report("Read all (specific locale):") do
      BenchmarkPost.all.each(&:title_de)
    end

    # Query benchmarks
    x.report("Query: match title:") do
      BenchmarkPost.international(title: "Title 500", locale: :en).to_a
    end

    x.report("Query: search title:") do
      BenchmarkPost.international(title: "Title 5", match: :partial, locale: :en).to_a
    end

    x.report("Query: sort by title:") do
      BenchmarkPost.international_order(:title, locale: :en).limit(100).to_a
    end

    x.report("Query: translated check:") do
      BenchmarkPost.translated(:title, :body, locale: :de).count
    end

    x.report("Query: untranslated check:") do
      BenchmarkPost.untranslated(:title, locale: :es).count
    end

    # Update benchmark
    x.report("Update #{count} records:") do
      BenchmarkPost.find_each do |p|
        p.title = "Updated #{p.id}"
        p.save!
      end
    end
  end

  storage_size = measure_storage("benchmark_posts", adapter)
  puts ""
  puts "Storage: #{format_size(storage_size)}"
  puts "Memory: #{%x(ps -o rss= -p #{Process.pid}).to_i / 1024} MB"

  storage_size
end

def run_mobility_benchmarks(count, adapter, backend_name)
  MobilityPost.delete_all
  ActiveRecord::Base.connection.execute("DELETE FROM mobility_string_translations")
  ActiveRecord::Base.connection.execute("DELETE FROM mobility_text_translations")

  puts "Mobility (#{backend_name}) Results:"
  puts ""

  Benchmark.bm(25) do |x|
    # Write benchmark
    x.report("Create #{count} records:") do
      count.times do |i|
        post = MobilityPost.new(status: i.even? ? "published" : "draft")
        I18n.with_locale(:en) do
          post.title = "Title #{i}"
          post.body = "Body content #{i}"
        end
        I18n.with_locale(:de) do
          post.title = "Titel #{i}"
          post.body = "Inhalt #{i}"
        end
        I18n.with_locale(:fr) { post.title = "Titre #{i}" }
        post.save!
      end
    end

    # Read benchmarks
    x.report("Read all (current locale):") do
      MobilityPost.all.each(&:title)
    end

    x.report("Read all (specific locale):") do
      I18n.with_locale(:de) do
        MobilityPost.all.each(&:title)
      end
    end

    # Query benchmarks
    x.report("Query: where title:") do
      MobilityPost.i18n.where(title: "Title 500").to_a
    end

    x.report("Query: search title:") do
      MobilityPost.i18n.where("title LIKE ?", "%Title 5%").to_a
    rescue StandardError
      []
    end

    x.report("Query: order by title:") do
      MobilityPost.i18n.order(:title).limit(100).to_a
    end

    # Update benchmark
    x.report("Update #{count} records:") do
      MobilityPost.find_each do |p|
        p.title = "Updated #{p.id}"
        p.save!
      end
    end
  end

  storage_size = measure_mobility_table_storage(adapter)
  puts ""
  puts "Storage: #{format_size(storage_size)}"
  puts "Memory: #{%x(ps -o rss= -p #{Process.pid}).to_i / 1024} MB"

  storage_size
end

def run_mobility_json_benchmarks(count, adapter)
  MobilityJsonPost.delete_all

  puts "Mobility (JSON) Results:"
  puts ""

  Benchmark.bm(25) do |x|
    # Write benchmark
    x.report("Create #{count} records:") do
      count.times do |i|
        post = MobilityJsonPost.new(status: i.even? ? "published" : "draft")
        I18n.with_locale(:en) do
          post.title = "Title #{i}"
          post.body = "Body content #{i}"
        end
        I18n.with_locale(:de) do
          post.title = "Titel #{i}"
          post.body = "Inhalt #{i}"
        end
        I18n.with_locale(:fr) { post.title = "Titre #{i}" }
        post.save!
      end
    end

    # Read benchmarks
    x.report("Read all (current locale):") do
      MobilityJsonPost.all.each(&:title)
    end

    x.report("Read all (specific locale):") do
      I18n.with_locale(:de) do
        MobilityJsonPost.all.each(&:title)
      end
    end

    # Query benchmarks (JSON backend queries - often fail)
    x.report("Query: where title:") do
      MobilityJsonPost.i18n.where(title: "Title 500").to_a
    rescue StandardError
      # JSON backend querying is buggy
      []
    end

    x.report("Query: search title:") do
      MobilityJsonPost.i18n.where("title LIKE ?", "%Title 5%").to_a
    rescue StandardError
      []
    end

    x.report("Query: order by title:") do
      MobilityJsonPost.i18n.order(:title).limit(100).to_a
    rescue StandardError
      []
    end

    # Update benchmark
    x.report("Update #{count} records:") do
      MobilityJsonPost.find_each do |p|
        p.title = "Updated #{p.id}"
        p.save!
      end
    end
  end

  storage_size = measure_storage("mobility_json_posts", adapter)
  puts ""
  puts "Storage: #{format_size(storage_size)}"
  puts "Memory: #{%x(ps -o rss= -p #{Process.pid}).to_i / 1024} MB"

  storage_size
end
