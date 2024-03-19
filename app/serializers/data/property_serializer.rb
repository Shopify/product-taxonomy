# frozen_string_literal: true

module Serializers
  module Data
    class PropertySerializer < ObjectSerializer
      def serialize(property)
        {
          "id" => property.id,
          "name" => property.name,
          "friendly_id" => property.friendly_id,
          "values" => property.property_values.reorder(:id).map { PropertyValueSerializer.serialize(_1) },
        }
      end

      def deserialize(hash)
        Property.new(
          id: hash["id"],
          friendly_id: hash["friendly_id"],
          name: hash["name"],
          property_value_ids: hash["values"].map { _1["id"] },
        )
      end
    end
  end
end
