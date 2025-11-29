# frozen_string_literal: true

class Blog < ActiveRecord::Base
  include Internationalize::Model

  international :title, :body
end
