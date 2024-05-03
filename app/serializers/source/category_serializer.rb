# frozen_string_literal: true

module Source
  class CategorySerializer
    class << self
      def unpack(hash)
        {
          "id" => hash["id"],
          "parent_id" => Category.parent_id_of(hash["id"]),
          "name" => hash["name"],
        }
      end

      def unpack_all(hash_list)
        hash_list.map { unpack(_1) }
      end

      def pack(category)
        {
          "id" => category.id,
          "name" => category.name,
          "children" => category.children.map(&:id),
          "attributes" => category.properties.reorder(:id).pluck(:friendly_id),
        }
      end

      def pack_all(categories)
        categories.map { pack(_1) }
      end
    end
  end
end
