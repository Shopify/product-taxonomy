# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  has_many :categories_properties, dependent: :destroy, foreign_key: :property_friendly_id, primary_key: :friendly_id
  has_many :categories, through: :categories_properties

  has_many :properties_property_values, dependent: :destroy
  has_many :property_values, through: :properties_property_values, foreign_key: :property_value_friendly_id

  belongs_to :parent,
    class_name: "Property",
    optional: true,
    foreign_key: :parent_friendly_id,
    primary_key: :friendly_id

  def property_value_friendly_ids=(ids)
    self.property_values = PropertyValue.where(friendly_id: ids)
  end

  validates :name, presence: true
  validates :friendly_id, presence: true, uniqueness: true
  validates :handle, presence: true
  validate :property_values_match_base, if: :extended?

  def gid
    "gid://shopify/TaxonomyAttribute/#{id}"
  end
end
