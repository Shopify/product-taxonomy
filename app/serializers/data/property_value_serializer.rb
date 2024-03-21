# frozen_string_literal: true

module Serializers
  module Data
    class PropertyValueSerializer < ObjectSerializer
      class << self
        delegate(:deserialize_for_insert_all, to: :instance)
      end

      def serialize(property_value)
        {
          "id" => property_value.id,
          "name" => property_value.name,
        }
      end

      def deserialize(hash)
        PropertyValue.new(**attributes_from(hash))
      end

      def deserialize_for_insert_all(array)
        array.map { attributes_from(_1) }
      end

      private

      def attributes_from(hash)
        {
          id: hash["id"],
          name: hash["name"],
        }
      end
    end
  end
end
