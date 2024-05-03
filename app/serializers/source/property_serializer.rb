# frozen_string_literal: true

module Source
  class PropertySerializer
    class << self
      def unpack(hash)
        {
          "id" => hash["id"],
          "friendly_id" => hash["friendly_id"],
          "name" => hash["name"],
          "handle" => hash["handle"],
          "base_friendly_id" => hash["values_from"],
        }
      end

      def unpack_all(hash_list)
        hash_list.map { unpack(_1) }
      end

      def pack(property)
        {
          "id" => property.id,
          "name" => property.name,
          "friendly_id" => property.friendly_id,
          "handle" => property.handle,
          "values" => property.property_values.reorder(:id).map { PropertyValueSerializer.pack(_1) },
        }
      end

      def pack_all(properties)
        properties.map { pack(_1) }
      end
    end
  end
end
