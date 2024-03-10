module Serializers
  module Data
    class CategorySerializer < ObjectSerializer
      def serialize(category)
        {
          "id" => category.id,
          "name" => category.name,
          "children" => category.children.map(&:id),
          "attributes" => category.properties.reorder(:id).map(&:friendly_id),
        }
      end

      def deserialize(hash)
        id = hash["id"].downcase
        parent_id = id.split("-")[0...-1].join("-").presence
        name = hash["name"]

        Category.new(id:, parent_id:, name:).tap do |category|
          category.child_ids = hash["children"] if hash["children"]
          category.property_ids = Property.where(friendly_id: hash["attributes"]).pluck(:id) if hash["attributes"]
        end
      end
    end
  end
end
