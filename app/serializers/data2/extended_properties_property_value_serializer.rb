# frozen_string_literal: true

module Data2
  class ExtendedPropertiesPropertyValueSerializer
    class << self
      def unpack(hash)
        base_property = Property.find_by!(friendly_id: hash["base_friendly_id"])
        base_property.property_values.map do |value|
          {
            "property_id" => hash["id"],
            "property_value_friendly_id" => value.friendly_id,
          }
        end
      end

      def unpack_all(hash_list)
        hash_list.flat_map { unpack(_1) }
      end
    end
  end
end
