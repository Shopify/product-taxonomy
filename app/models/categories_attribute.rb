# frozen_string_literal: true

class CategoriesAttribute < ApplicationRecord
  belongs_to :category
  belongs_to :related_attribute, class_name: "Attribute", foreign_key: :attribute_friendly_id, primary_key: :friendly_id

  class << self
    #
    # `data/` deserialization

    def insert_all_from_data(data, ...)
      insert_all(Array(data).flat_map { rows_from_data(_1) }, ...)
    end

    private

    def rows_from_data(data)
      data["attributes"].map do |friendly_id|
        {
          "category_id" => data["id"],
          "attribute_friendly_id" => friendly_id,
        }
      end
    end
  end
end
