# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  has_many :categories_properties, dependent: :destroy, foreign_key: :property_friendly_id, primary_key: :friendly_id
  has_many :categories, through: :categories_properties

  has_many :properties_property_values, dependent: :destroy
  has_many :property_values, through: :properties_property_values, foreign_key: :property_value_friendly_id

  def property_value_friendly_ids
    property_values.pluck(:friendly_id)
  end

  def property_value_friendly_ids=(ids)
    self.property_values = PropertyValue.where(friendly_id: ids)
  end

  validates :name, presence: true

  def gid
    "gid://shopify/Taxonomy/Attribute/#{id}"
  end
end
