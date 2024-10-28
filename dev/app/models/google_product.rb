# frozen_string_literal: true

class GoogleProduct < Product
  store :payload, coder: JSON, accessors: [:product_category_id]
end
