# frozen_string_literal: true

module SourceData
  class PropertyValueSerializer < ObjectSerializer
    class << self
      delegate(:deserialize_for_insert_all, to: :instance)
    end

    def serialize(property_value)
      {
        "id" => property_value.id,
        "name" => property_value.name,
        "friendly_id" => property_value.friendly_id,
      }
    end

    def deserialize(hash)
      ::PropertyValue.new(**attributes_from(hash))
    end

    def deserialize_for_insert_all(array)
      array.map { attributes_from(_1) }
    end

    private

    def attributes_from(hash)
      {
        id: hash["id"],
        name: hash["name"],
        friendly_id: hash["friendly_id"],
        primary_property_friendly_id: hash["friendly_id"].split("__").first,
      }
    end
  end
end
