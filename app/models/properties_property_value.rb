# frozen_string_literal: true

class PropertiesPropertyValue < ApplicationRecord
  belongs_to :property
  belongs_to :property_value, foreign_key: :property_value_friendly_id, primary_key: :friendly_id

  class << self
    #
    # `data/` deserialization

    def insert_all_from_data!(data, ...)
      insert_all!(Array(data).flat_map { rows_from_data(_1) }, ...)
    end

    private

    def rows_from_data(data)
      values, friendly_id, id = data.values_at("values", "base_friendly_id", "id")

      value_friendly_ids = values || Property.find_by!(friendly_id:).property_values.pluck(:friendly_id)

      value_friendly_ids.map do |value_friendly_id|
        {
          "property_id" => id,
          "property_value_friendly_id" => value_friendly_id,
        }
      end
    end
  end
end
