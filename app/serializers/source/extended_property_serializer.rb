# frozen_string_literal: true

module Source
  class ExtendedPropertySerializer
    class << self
      def unpack(hash)
        {
          "name" => hash["name"],
          "handle" => hash["handle"],
          "friendly_id" => hash["friendly_id"],
          "base_friendly_id" => hash["values_from"],
        }
      end

      def unpack_all(hash_list)
        hash_list.map { unpack(_1) }
      end

      def pack(property)
        {
          "name" => property.name,
          "handle" => property.handle,
          "friendly_id" => property.friendly_id,
          "values_from" => property.base_friendly_id,
        }
      end

      def pack_all(properties)
        properties.map { pack(_1) }
      end
    end
  end
end
