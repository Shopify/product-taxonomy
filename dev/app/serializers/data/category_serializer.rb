module Serializers
  module Data
    class CategorySerializer < ObjectSerializer
      def serialize(category)
        {
          id: category.id,
          name: category.name,
          children_ids: category.children.map(&:id),
          attribute_friendly_ids: category.properties.map(&:friendly_id),
        }
      end

      def deserialize(hash)
        Category.new(
          id: hash["id"].downcase,
          name: hash["name"],
          child_ids: hash["children_ids"],
          property_ids: Property.where(friendly_id: hash["attribute_friendly_ids"]).pluck(:id),
        )
      end
    end
  end
end
