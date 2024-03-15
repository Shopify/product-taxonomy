# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  has_and_belongs_to_many :categories
  has_and_belongs_to_many :property_values

  validates :name, presence: true

  def gid
    "gid://shopify/Taxonomy/Attribute/#{id}"
  end
end
