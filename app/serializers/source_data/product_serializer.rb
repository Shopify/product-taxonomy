# frozen_string_literal: true

module SourceData
  class ProductSerializer < ObjectSerializer
    def serialize(product)
      payload = {}
      if product.is_a?(ShopifyProduct)
        payload[:product_category_id] = product.product_category_id
        payload[:attributes] = product.properties.map(&:deep_symbolize_keys) if product.properties.present?
      end
      {
        payload: payload,
        type: product.type,
      }
    end

    def deserialize(payload, product_type)
      if product_type == "ShopifyProduct"
        properties = payload.delete("attributes")
        payload["properties"] = properties
      end
      Product.new(payload: payload, type: product_type)
    end
  end
end
