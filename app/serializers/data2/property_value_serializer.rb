# frozen_string_literal: true

module Data2
  class PropertyValueSerializer
    class << self
      def unpack(hash)
        {
          "id" => hash["id"],
          "name" => hash["name"],
          "handle" => hash["handle"],
          "friendly_id" => hash["friendly_id"],
          "primary_property_friendly_id" => hash["friendly_id"].split("__").first,
        }
      end

      def unpack_all(hash_list)
        hash_list.map { unpack(_1) }
      end

      def pack(property_value)
        {
          "id" => property_value.id,
          "name" => property_value.name,
          "friendly_id" => property_value.friendly_id,
          "handle" => property_value.handle,
        }
      end

      def pack_all(property_values)
        property_values.map { pack(_1) }
      end
    end
  end
end
