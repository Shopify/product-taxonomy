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
        {
          "properties" => data["attributes"],
          "product_category_id" => Category.gid(data["product_category_id"]),
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
end
