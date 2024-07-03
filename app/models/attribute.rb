# frozen_string_literal: true

class Attribute < ApplicationRecord
  default_scope { order(:name) }

  scope :base, -> { where(base_friendly_id: nil) }
  scope :extended, -> { where.not(base_friendly_id: nil) }

  has_many :categories_attributes,
    dependent: :destroy,
    foreign_key: :attribute_friendly_id,
    primary_key: :friendly_id,
    inverse_of: :related_attribute
  has_many :categories, through: :categories_attributes
  has_many :attributes_values,
    dependent: :destroy,
    foreign_key: :attribute_id,
    primary_key: :id,
    inverse_of: :related_attribute
  has_many :values, through: :attributes_values

  belongs_to :base_attribute,
    class_name: "Attribute",
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id,
    optional: true

  has_many :extended_attributes,
    class_name: "Attribute",
    foreign_key: :base_friendly_id,
    primary_key: :friendly_id

  validates :name, presence: true
  validates :friendly_id, presence: true, uniqueness: true
  validates :handle, presence: true
  validates :description, presence: true
  validate :values_match_base, if: :extended?

  LOCALIZATION_PATH = "data/localizations/attributes/*.yml"

  class << self
    #
    # `data/` deserialization

    def new_from_data(data)
      new(row_from_data(data))
    end

    def insert_all_from_data(data, ...)
      insert_all!(Array(data).map { row_from_data(_1) }, ...)
    end

    def localizations
      @localizations ||= Dir.glob(LOCALIZATION_PATH).each_with_object({}) do |file, localizations|
        locale = File.basename(file, ".yml")
        localizations[locale] = YAML.load_file(file).dig(locale, "attributes")
      end
    end

    def find_localization(locale, id, key)
      localizations.dig(locale, id, key)
    end

    #
    # `dist/` serialization

    def as_json(attributes, version:, locale: "en")
      {
        "version" => version,
        "attributes" => attributes.map { _1.as_json(locale:) },
      }
    end

    def as_json_for_docs(locale: "en")
      Attribute.where(base_friendly_id: nil).map { _1.as_json_for_docs(locale:) }
    end

    def as_txt(attributes, version:, locale: "en")
      header = <<~HEADER
        # Shopify Product Taxonomy - Attributes: #{version}
        # Format: {GID} : {Attribute name}
      HEADER
      padding = reorder("LENGTH(id) desc").first.gid.size
      [
        header,
        *attributes.map { _1.as_txt(padding:, locale:) },
      ].join("\n")
    end

    private

    def row_from_data(data)
      {
        "id" => data["id"],
        "name" => data["name"],
        "handle" => data["handle"],
        "description" => data["description"],
        "friendly_id" => data["friendly_id"],
        "base_friendly_id" => data["values_from"],
      }.compact
    end
  end

  def gid
    if base?
      "gid://shopify/TaxonomyAttribute/#{id}"
    else
      base_attribute.gid
    end
  end

  def name(locale: "en")
    self.class.find_localization(locale, friendly_id, "name") || super()
  end

  def base?
    base_attribute.nil?
  end

  def extended?
    !base?
  end

  def sorted_values
    ValueSorter.sort_values_for_attribute(handle, values)
  end

  def value_friendly_ids=(friendly_id)
    self.values = Value.where(friendly_id:)
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
        "description" => description,
        "values" => values.reorder(:id).map(&:friendly_id),
      }
    else
      {
        "name" => name,
        "handle" => handle,
        "description" => description,
        "friendly_id" => friendly_id,
        "values_from" => base_friendly_id,
      }
    end
  end

  #
  # `dist/` serialization

  def as_json(locale: "en")
    {
      "id" => gid,
      "name" => name(locale:),
      "handle" => handle,
      "description" => description,
      "extended_attributes" => extended_attributes.map do
        {
          "name" => _1.name(locale:),
          "handle" => _1.handle,
        }
      end,
      "values" => values.map do
        {
          "id" => _1.gid,
          "name" => _1.name(locale:),
          "handle" => _1.handle,
        }
      end,
    }
  end

  def as_json_for_docs(locale: "en")
    {
      "id" => gid,
      "name" => name(locale:),
      "handle" => handle,
      "description" => description,
      "extended_attributes" => extended_attributes.map do
        {
          "name" => _1.name(locale:),
          "handle" => _1.handle,
        }
      end,
      "values" => sorted_values.map do
        {
          "id" => _1.gid,
          "name" => _1.name(locale:),
          "handle" => _1.handle,
        }
      end,
    }
  end

  def as_txt(padding: 0, locale: "en")
    "#{gid.ljust(padding)} : #{name(locale:)}"
  end

  private

  def values_match_base
    return if values == base_attribute.values

    errors.add(:values, "must match base attribute's values")
  end
end
