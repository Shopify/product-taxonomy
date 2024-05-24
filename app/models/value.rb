# frozen_string_literal: true

class Value < ApplicationRecord
  default_scope { order(Arel.sql("CASE WHEN name = 'Other' THEN 1 ELSE 0 END, name")) }

  has_many :attributes_values,
    dependent: :destroy,
    foreign_key: :value_friendly_id,
    primary_key: :friendly_id,
    inverse_of: :value
  has_many :related_attributes, through: :attributes_values

  belongs_to :primary_attribute,
    class_name: "Attribute",
    foreign_key: :primary_attribute_friendly_id,
    primary_key: :friendly_id

  validates :name, presence: true
  validates :friendly_id, presence: true, uniqueness: true
  validates :handle, presence: true, uniqueness: { scope: :primary_attribute_friendly_id }
  validates :primary_attribute, presence: true

  LOCALIZATION_PATH = "data/localizations/values/*.yml"

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
        localizations[locale] = YAML.load_file(file).dig(locale, "values")
      end
    end

    def find_localization(locale, id, key)
      localizations.dig(locale, id, key)
    end

    #
    # `dist/` serialization

    def as_json(values, version:, locale: "en")
      {
        "version" => version,
        "values" => values.map { _1.as_json(locale:) },
      }
    end

    def as_txt(values, version:, locale: "en")
      header = <<~HEADER
        # Shopify Product Taxonomy - Attribute Values: #{version}
        # Format: {GID} : {Value name} [{Attribute name}]
      HEADER
      padding = reorder("LENGTH(id) desc").first.gid.size
      [
        header,
        *values.map { _1.as_txt(padding: padding, locale:) },
      ].join("\n")
    end

    private

    def row_from_data(data)
      {
        "id" => data["id"],
        "name" => data["name"],
        "handle" => data["handle"],
        "friendly_id" => data["friendly_id"],
        "primary_attribute_friendly_id" => data["friendly_id"].split("__").first,
      }
    end
  end

  def gid
    "gid://shopify/TaxonomyValue/#{id}"
  end

  def name(locale: "en")
    self.class.find_localization(locale, friendly_id, "name") || super()
  end

  def full_name(locale: "en")
    "#{name(locale:)} [#{primary_attribute.name(locale:)}]"
  end

  def primary_attribute_friendly_id=(friendly_id)
    self.primary_attribute = Attribute.find_by(friendly_id:)
  end

  #
  # `data/` serialization

  def as_json_for_data
    {
      "id" => id,
      "name" => name,
      "friendly_id" => friendly_id,
      "handle" => handle,
    }
  end

  #
  # `dist/` serialization

  def as_json(locale: "en")
    {
      "id" => gid,
      "name" => name(locale:),
      "handle" => handle,
    }
  end

  def as_txt(padding: 0, locale: "en")
    "#{gid.ljust(padding)} : #{full_name(locale:)}"
  end
end
