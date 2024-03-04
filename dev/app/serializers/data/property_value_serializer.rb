module Serializers
  module Data
    class PropertyValueSerializer < ObjectSerializer
      def serialize(property_value)
        {
          id: property.id,
          friendly_id: property.friendly_id,
          name: property.name,
        }
      end

      def deserialize(hash)
        PropertyValue.new(
          id: hash["id"],
          friendly_id: hash["friendly_id"],
          name: hash["name"],
        )
      end
    end
  end
end
