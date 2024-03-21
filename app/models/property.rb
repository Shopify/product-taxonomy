# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  has_and_belongs_to_many :categories,
    join_table: :categories_properties,
    foreign_key: :property_friendly_id,
    association_foreign_key: :category_id

  has_and_belongs_to_many :property_values,
    join_table: :properties_property_values

  validates :name, presence: true

  def gid
    "gid://shopify/Taxonomy/Attribute/#{id}"
  end
end
