# frozen_string_literal: true

class AttributesValue < ApplicationRecord
  self.primary_key = [:attribute_id, :value_friendly_id]

  belongs_to :related_attribute, class_name: "Attribute", foreign_key: :attribute_id, primary_key: :id
  belongs_to :value, foreign_key: :value_friendly_id, primary_key: :friendly_id

  class << self
    #
    # `data/` deserialization

    def insert_all_from_data(data, ...)
      insert_all!(Array(data).flat_map { rows_from_data(_1) }, ...)
    end

    private

    def rows_from_data(data)
      values, friendly_id, id = data.values_at("values", "base_friendly_id", "id")

      value_friendly_ids = values || Attribute.find_by!(friendly_id:).values.pluck(:friendly_id)

      value_friendly_ids.map do |value_friendly_id|
        {
          "attribute_id" => id,
          "value_friendly_id" => value_friendly_id,
        }
      end
    end
  end
end
