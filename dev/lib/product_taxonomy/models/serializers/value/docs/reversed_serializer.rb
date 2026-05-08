# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Docs
        module ReversedSerializer
          class << self
            def serialize_all
              {
                "values" => ProductTaxonomy::Value.all_values_sorted.map { |value| serialize(value) },
              }
            end

            # @param [Value] value The value to serialize.
            # @return [Hash] The serialized value. Categories aren't embedded — users navigate to the parent
            #   attribute page to see them, since duplicating the category list across every value of an
            #   attribute would explode the YAML by orders of magnitude.
            def serialize(value)
              attribute = value.primary_attribute
              {
                "id" => value.gid,
                "handle" => value.handle,
                "name" => value.name,
                "friendly_id" => value.friendly_id,
                "attribute" => attribute && {
                  "handle" => attribute.handle,
                  "name" => attribute.name,
                },
              }
            end
          end
        end
      end
    end
  end
end
