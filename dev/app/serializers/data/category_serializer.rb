module Serializers
  module Data
    class CategorySerializer < ObjectSerializer
      def serialize(category)
        {
          id: category.id,
          name: category.name,
          children_ids: category.children.map(&:id),
          attribute_ids: category.properties.map(&:id),
        }
      end

      def deserialize(hash)
        Category.new(
          id: hash["id"].downcase,
          name: hash["name"],
          child_ids: hash["children_ids"],
          property_ids: hash["attribute_ids"],
        )
      end
    end
  end
end
