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

    def find_or_create_from_data!(data, type:)
      find_or_create_by!(type:, payload: payload_for(data, type:))
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
      when "GoogleProduct"
        {
          "product_category_id" => data["product_category_id"],
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

  def as_json(options = {})
    super(options.merge({ methods: :type }))
  end

  def as_txt
    product_category_id.to_s
  end
end
