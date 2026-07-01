# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Data
        module DataSerializer
          class << self
            def serialize_all
              # Base attributes are sorted by ID, extended attributes are sorted by the order they were added
              extended_attributes, base_attributes = ProductTaxonomy::Attribute.all.partition(&:extended?)
              base_attributes.sort_by!(&:id)

              {
                "base_attributes" => base_attributes.map { serialize(_1) },
                "extended_attributes" => extended_attributes.map { serialize(_1) },
              }
            end

            # @param [Attribute] attribute
            # @return [Hash]
            def serialize(attribute)
              if attribute.extended?
                {
                  "name" => attribute.name,
                  "handle" => attribute.handle,
                  "description" => attribute.description,
                  "friendly_id" => attribute.friendly_id,
                  "values_from" => attribute.values_from.friendly_id,
                }
              else
                serialized = {
                  "id" => attribute.id,
                  "name" => attribute.name,
                  "description" => attribute.description,
                  "friendly_id" => attribute.friendly_id,
                  "handle" => attribute.handle,
                  "type" => attribute.type,
                  "sorting" => attribute.manually_sorted? ? "custom" : nil,
                }

                if attribute.measurement?
                  serialized.merge!(
                    "measurement_type" => attribute.measurement_type,
                    "supported_units" => attribute.supported_units,
                  )
                else
                  serialized["values"] = attribute.sorted_values.map(&:friendly_id)
                end

                serialized.compact
              end
            end
          end
        end
      end
    end
  end
end
