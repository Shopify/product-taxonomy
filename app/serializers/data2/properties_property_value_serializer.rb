# frozen_string_literal: true

module Data2
  class PropertiesPropertyValueSerializer
    class << self
      def unpack(hash)
        hash["values"].map do |friendly_id|
          {
            "property_id" => hash["id"],
            "property_value_friendly_id" => friendly_id,
          }
        end
      end

      def unpack_all(hash_list)
        hash_list.flat_map { unpack(_1) }
      end
    end
  end
end
