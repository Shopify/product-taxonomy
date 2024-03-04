module Serializers
  module Data
    class PropertyValueSerializer < ObjectSerializer
      def serialize(property_value)
        {
          id: property.id,
          name: property.name,
        }
      end

      def deserialize(hash)
        PropertyValue.new(
          id: hash["id"].split("-").last,
          name: hash["name"],
        )
      end
    end
  end
end
