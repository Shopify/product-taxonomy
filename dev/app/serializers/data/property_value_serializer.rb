# frozen_string_literal: true

module Serializers
  module Data
    class PropertyValueSerializer < ObjectSerializer
      def serialize(property_value)
        {
          "id" => property_value.id,
          "name" => property_value.name,
        }
      end

      def deserialize(hash)
        PropertyValue.new(
          id: hash["id"],
          name: hash["name"],
        )
      end
    end
  end
end
