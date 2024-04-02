# frozen_string_literal: true

class PropertyValue < ApplicationRecord
  default_scope { order(Arel.sql("CASE WHEN name = 'Other' THEN 1 ELSE 0 END, name")) }

  has_many :properties_property_values,
    dependent: :destroy,
    foreign_key: :property_value_friendly_id,
    primary_key: :friendly_id,
    inverse_of: :property_value
  has_many :properties, through: :properties_property_values

  validates :name, presence: true

  def gid
    "gid://shopify/TaxonomyValue/#{id}"
  end
end
