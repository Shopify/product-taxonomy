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
        "parent_friendly_id" => property.parent_friendly_id,
        "values" => property.property_values.reorder(:id).map { PropertyValueSerializer.serialize(_1) },
      }
    end

    def deserialize(hash)
      Property.new(**attributes_from(hash)).tap do |property|
        if hash["values_from"].present?
          property.property_values = Property.find_by!(friendly_id: hash["values_from"]).property_values
        else
          property.property_value_friendly_ids = hash["values"]
        end
      end
    end

    def deserialize_for_insert_all(array)
      array.map { attributes_from(_1) }
    end

    def deserialize_for_join_insert_all(array)
      array.flat_map do |hash|
        if hash["values_from"].present?
          property = Property.find_by!(friendly_id: hash["values_from"])

          next property.property_values.map do |value|
            {
              property_id: hash["id"],
              property_value_friendly_id: value.friendly_id,
            }
          end
        end

        hash["values"].map do |value_friendly_id|
          {
            property_id: hash["id"],
            property_value_friendly_id: value_friendly_id,
          }
        end
      end
    end

    private

    def attributes_from(hash)
      {
        id: hash["id"],
        friendly_id: hash["friendly_id"],
        name: hash["name"],
        parent_friendly_id: hash["values_from"],
      }
    end
  end
end
