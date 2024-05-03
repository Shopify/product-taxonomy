# frozen_string_literal: true

module Source
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
