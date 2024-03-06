module Serializers
  module Data
    class CategorySerializer < ObjectSerializer
      def serialize(category)
        {
          id: category.id,
          name: category.name,
          children: category.children.map(&:id),
          attributes: category.properties.map(&:friendly_id),
        }
      end

      def deserialize(hash)
        Category.new(
          id: hash["id"].downcase,
          name: hash["name"],
          child_ids: hash["children"],
          property_ids: Property.where(friendly_id: hash["attributes"]).pluck(:id),
        )
      end
    end
  end
end
