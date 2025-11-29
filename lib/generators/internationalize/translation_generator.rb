# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Internationalize
  module Generators
    class TranslationGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("translation/templates", __dir__)

      argument :model_name, type: :string, desc: "The model to add translations to"
      argument :attributes, type: :array, desc: "Attributes to make translatable"

      desc "Generates a migration to add translation columns to a model"

      def create_migration_file
        migration_template(
          "add_translations_migration.rb.erb",
          "db/migrate/add_#{attributes.join("_and_")}_translations_to_#{table_name}.rb",
        )
      end

      private

      def table_name
        model_name.tableize.tr("/", "_")
      end

      def migration_class_name
        "Add#{attributes.map(&:camelize).join("And")}TranslationsTo#{model_name.gsub("::", "").pluralize}"
      end
    end
  end
end
