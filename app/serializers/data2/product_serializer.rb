# frozen_string_literal: true

module SourceData
  class ProductSerializer
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
        payload["product_category_id"] = Category.gid(payload["product_category_id"])
      end
      Product.new(payload: payload, type: product_type)
    end
  end
end

module Data2
  class ProductSerializer
    class << self
      def unpack(hash)
        case hash["type"]
        when "ShopifyProduct"
          {
            "properties" => hash["attributes"],
            "product_category_id" => Category.gid(hash["product_category_id"]),
          }
        else
          {
            "product_category_id" => hash["product_category_id"],
          }
        end
      end

      def unpack_all(hash_list)
        hash_list.map { unpack(_1) }
      end

      def pack(product)
        {
          payload: packed_payload_for(product),
          type: product.type,
        }
      end

      def pack_all(products)
        products.map { pack(_1) }
      end

      private

      def packed_payload_for(product)
        case product
        when ShopifyProduct
          {
            "product_category_id" => product.product_category_id,
            "attributes" => product.properties&.map(&:deep_symbolize_keys),
          }.presence
        end
      end
    end
  end
end
