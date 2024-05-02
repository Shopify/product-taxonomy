# frozen_string_literal: true

module Data2
  class CategoriesPropertySerializer
    class << self
      def unpack(hash)
        hash["attributes"].map do |attribute|
          {
            "category_id" => hash["id"],
            "property_friendly_id" => attribute,
          }
        end
      end

      def unpack_all(data_list)
        data_list.flat_map { unpack(_1) }
      end
    end
  end
end
