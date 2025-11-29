# frozen_string_literal: true

class CreateBlogs < ActiveRecord::Migration[7.0]
  def change
    create_table(:blogs) do |t|
      t.json(:title_translations, default: {})
      t.json(:body_translations, default: {})
      t.string(:author)
      t.boolean(:published, default: false)
      t.timestamps
    end
  end
end
