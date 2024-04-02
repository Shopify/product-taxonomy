# frozen_string_literal: true

class PropertyValue < ApplicationRecord
  default_scope { order(Arel.sql("CASE WHEN name = 'Other' THEN 1 ELSE 0 END, name")) }

  has_many :properties_property_values,
    dependent: :destroy,
    foreign_key: :property_value_friendly_id,
    primary_key: :friendly_id,
    inverse_of: :property_value
  has_many :properties, through: :properties_property_values

  belongs_to :primary_property,
    class_name: "Property",
    foreign_key: :primary_property_friendly_id,
    primary_key: :friendly_id

  def primary_property_friendly_id=(id)
    self.primary_property = Property.find_by(friendly_id: id)
  end

  validates :name, presence: true
  validates :friendly_id, presence: true

  def gid
    "gid://shopify/TaxonomyValue/#{id}"
  end

  def full_name
    [primary_property&.name, name].compact.join(" > ")
  end
end
