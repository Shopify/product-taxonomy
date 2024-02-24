module Serializers
  module Data
    class PropertySerializer < ObjectSerializer
      def serialize(property)
        {
          id: property.id,
          name: property.name,
          values: property.property_values.map { PropertyValueSerializer.serialize(_1) }
        }
      end

      def deserialize(hash)
        Property.new(
          id: hash["id"],
          name: hash["name"],
          property_values: hash["values"].map { PropertyValueSerializer.deserialize(_1) }
        )
      end
    end
  end
end
