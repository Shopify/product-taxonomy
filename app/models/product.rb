# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :mapping_rules
  serialize :payload, coder: JSON

  class << self
    #
    # `data/` deserialization

    def find_from_data(data, type:)
      find_by(type:, payload: payload_for(data, type:))
    end

    def find_or_create_from_data!(data, type:, full_name:)
      find_or_create_by!(type:, payload: payload_for(data, type:), full_name:)
    end

    def full_name_map
      @full_name_map ||= {}
    end

    private

    def payload_for(data, type:)
      case type
      when "ShopifyProduct"
        category_id = if data["product_category_id"].is_a?(Array)
          data["product_category_id"].map { Category.gid(_1) }
        else
          Category.gid(data["product_category_id"])
        end

        {
          "properties" => data["attributes"],
          "product_category_id" => category_id,
        }
      else
        data.slice("product_category_id")
      end
    end
  end

  #
  # `data/` serialization

  def as_json_for_data
    payload = case product
    when ShopifyProduct
      {
        "product_category_id" => product.product_category_id,
        "attributes" => product.properties&.map(&:deep_symbolize_keys),
      }
    end
    {
      payload: payload.presence,
      type: type,
    }
  end

  #
  # `dist/` serialization

  def as_json(integration_version: nil)
    {
      "attributes" => get_attributes,
      "category" => get_category(integration_version:),
    }.compact
  end

  def as_txt
    full_name.to_s
  end

  private

  def get_attributes
    payload["properties"]&.map do |property|
      {
        "attribute" => Attribute.find_by(friendly_id: property["attribute"]).gid,
        "value" => Value.find_by(friendly_id: property["value"])&.gid,
      }
    end
  end

  def get_category(integration_version:)
    if payload["product_category_id"].is_a?(Array)
      payload["product_category_id"].map do |category_id|
        get_category_hash(category_id:, integration_version:)
      end
    else
      category_id = parse_category_id(payload["product_category_id"])
      get_category_hash(category_id:, integration_version:)
    end
  end

  def parse_category_id(category_id)
    category_id.split("/").last
  end

  def get_category_hash(category_id:, integration_version:)
    category_id = parse_category_id(category_id)
    if integration_version.nil?
      Category.find_by(id: category_id)&.as_json&.slice("id", "full_name")
    else
      {
        "id" => category_id,
        "full_name" => integration_full_name(category_id: category_id, integration_version: integration_version),
      }
    end
  end

  def integration_full_name(category_id:, integration_version:)
    full_name_map(integration_version:)[category_id.to_s]
  end

  def full_name_map(integration_version:)
    unless self.class.full_name_map.key?(integration_version)
      categories = YAML.load_file(File.join(Rails.root, "data/integrations/#{integration_version}/full_names.yml"))
      self.class.full_name_map[integration_version] = categories.each_with_object({}) do |category, hash|
        hash[category["id"].to_s] = category["full_name"]
      end
    end
    self.class.full_name_map[integration_version]
  end
end
