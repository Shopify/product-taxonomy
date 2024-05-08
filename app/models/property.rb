# frozen_string_literal: true

class Property < ApplicationRecord
  default_scope { order(:name) }

  scope :base, -> { where(base_friendly_id: nil) }
  scope :extended, -> { where.not(base_friendly_id: nil) }

  has_many :categories_properties,
    dependent: :destroy,
    foreign_key: :property_friendly_id,
    primary_key: :friendly_id,
    inverse_of: :property
  has_many :categories, through: :categories_properties
  has_many :properties_property_values,
    dependent: :destroy,
    foreign_key: :property_id,
    primary_key: :id,
    inverse_of: :property
  has_many :property_values, through: :properties_property_values

  belongs_to :base_property,
    class_name: "Property",
    optional: true,
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id

  has_many :extended_properties,
    class_name: "Property",
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id

  validates :name, presence: true
  validates :friendly_id, presence: true, uniqueness: true
  validates :handle, presence: true
  validate :property_values_match_base, if: :extended?

  class << self
    #
    # `data/` deserialization

    def new_from_data(data)
      new(row_from_data(data))
    end

    def insert_all_from_data(data, ...)
      insert_all(Array(data).map { row_from_data(_1) }, ...)
    end

    #
    # `dist/` serialization

    def as_json(properties, version:)
      {
        "version" => version,
        "attributes" => properties.map(&:as_json),
      }
    end

    def as_txt(properties, version:)
      header = <<~HEADER
        # Shopify Product Taxonomy - Attributes: #{version}
        # Format: {GID} : {Attribute name}
      HEADER
      padding = reorder("LENGTH(id) desc").first.gid.size
      [
        header,
        *properties.map { _1.as_txt(padding:) },
      ].join("\n")
    end

    private

    def row_from_data(data)
      {
        "id" => data["id"],
        "name" => data["name"],
        "handle" => data["handle"],
        "friendly_id" => data["friendly_id"],
        "base_friendly_id" => data["values_from"],
      }.compact
    end
  end

  def gid
    if base?
      "gid://shopify/TaxonomyAttribute/#{id}"
    else
      base_property.gid
    end
  end

  def base?
    base_property.nil?
  end

  def extended?
    !base?
  end

  def property_value_friendly_ids=(friendly_id)
    self.property_values = PropertyValue.where(friendly_id:)
  end

  #
  # `data/` serialization

  def as_json_for_data
    if base?
      {
        "id" => id,
        "name" => name,
        "friendly_id" => friendly_id,
        "handle" => handle,
        "values" => property_values.reorder(:id).map(&:friendly_id),
      }
    else
      {
        "name" => name,
        "handle" => handle,
        "friendly_id" => friendly_id,
        "values_from" => base_friendly_id,
      }
    end
  end

  #
  # `dist/` serialization

  def as_json
    {
      "id" => gid,
      "name" => name,
      "handle" => handle,
      "extended_attributes" => extended_properties.map do
        {
          "name" => _1.name,
          "handle" => _1.handle,
        }
      end,
      "values" => property_values.map do
        {
          "id" => _1.gid,
          "name" => _1.name,
          "handle" => _1.handle,
        }
      end,
    }
  end

  def as_txt(padding: 0)
    "#{gid.ljust(padding)} : #{name}"
  end

  private

  def property_values_match_base
    return if property_values == base_property.property_values

    errors.add(:property_values, "must match base's property values")
  end
end
