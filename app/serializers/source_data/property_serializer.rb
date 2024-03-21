# frozen_string_literal: true

module SourceData
  class PropertySerializer < ObjectSerializer
    class << self
      delegate(:deserialize_for_insert_all, :deserialize_for_join_insert_all, to: :instance)
    end

    def serialize(property)
      {
        "id" => property.id,
        "name" => property.name,
        "friendly_id" => property.friendly_id,
        "values" => property.property_values.reorder(:id).map { PropertyValueSerializer.serialize(_1) },
      }
    end

    def deserialize(hash)
      Property.new(
        id: hash["id"],
        friendly_id: hash["friendly_id"],
        name: hash["name"],
        property_value_ids: hash["values"].map { _1["id"] },
      )
    end

    def deserialize_for_insert_all(array)
      array.map do |hash|
        {
          id: hash["id"],
          friendly_id: hash["friendly_id"],
          name: hash["name"],
        }
      end
    end

    def deserialize_for_join_insert_all(array)
      array.flat_map do |hash|
        hash["values"].map do |value_hash|
          {
            property_id: hash["id"],
            property_value_id: value_hash["id"],
          }
        end
      end
    end
  end
end
