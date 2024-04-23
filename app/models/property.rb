# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  scope :base, -> { where(base_friendly_id: nil) }
  scope :extended, -> { where.not(base_friendly_id: nil) }

  has_many :categories_properties, dependent: :destroy, foreign_key: :property_friendly_id, primary_key: :friendly_id
  has_many :categories, through: :categories_properties

  has_many :properties_property_values, dependent: :destroy
  has_many :property_values, through: :properties_property_values, foreign_key: :property_value_friendly_id

  belongs_to :base_property,
    class_name: "Property",
    optional: true,
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id

  has_many :extended_properties,
    class_name: "Property",
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id

  def property_value_friendly_ids=(ids)
    self.property_values = PropertyValue.where(friendly_id: ids)
  end

  validates :name, presence: true
  validates :friendly_id, presence: true, uniqueness: true
  validate :property_values_match_base, if: :extended?

  def gid
    if extended?
      base_property.gid
    else
      "gid://shopify/TaxonomyAttribute/#{id}"
    end
  end

  def base?
    base_property.nil?
  end

  def extended?
    !base?
  end

  private

  def property_values_match_base
    return if property_values == base_property.property_values

    errors.add(:property_values, "must match base's property values")
  end
end
