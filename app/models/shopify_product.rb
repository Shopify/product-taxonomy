# frozen_string_literal: true

class ShopifyProduct < Product
  store :payload, coder: JSON, accessors: [:product_category_id, :properties]
end
