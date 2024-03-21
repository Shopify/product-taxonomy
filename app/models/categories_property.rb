# frozen_string_literal: true

class CategoriesProperty < ApplicationRecord
  belongs_to :category
  belongs_to :property, foreign_key: :property_friendly_id, primary_key: :friendly_id
end
