# frozen_string_literal: true

module SourceData
  class CategorySerializer < ObjectSerializer
    class << self
      delegate(:deserialize_for_insert_all, :deserialize_for_join_insert_all, to: :instance)
    end

    def serialize(category)
      {
        "id" => category.id,
        "name" => category.name,
        "children" => category.children.map(&:id),
        "attributes" => category.properties.reorder(:id).map(&:friendly_id),
      }
    end

    def deserialize(hash)
      Category.new(**attributes_from(hash)).tap do |category|
        category.child_ids = hash["children"] if hash["children"]
        category.property_friendly_ids = hash["attributes"] if hash["attributes"]
      end
    end

    def deserialize_for_insert_all(array)
      array.map { attributes_from(_1) }
    end

    def deserialize_for_join_insert_all(array)
      array.flat_map do |hash|
        category_id = hash["id"].downcase
        hash["attributes"].map do |property_friendly_id|
          { category_id:, property_friendly_id: }
        end
      end
    end

    private

    def attributes_from(hash)
      {
        id: hash["id"].downcase,
        parent_id: hash["id"].split("-")[0...-1].join("-").presence,
        name: hash["name"],
      }
    end
  end
end
