# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        module BaseAndExtendedSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Attribute.sorted_base_attributes.flat_map do |attribute|
                extended_attributes = attribute.extended_attributes.sort_by(&:name).map do |extended_attribute|
                  serialize(extended_attribute)
                end
                extended_attributes + [serialize(attribute)]
              end
            end

            # @param [Attribute] attribute
            # @return [Hash]
            def serialize(attribute)
              result = {
                "id" => attribute.gid,
                "name" => attribute.extended? ? attribute.base_attribute.name : attribute.name,
                "handle" => attribute.handle,
                "extended_name" => attribute.extended? ? attribute.name : nil,
                "values" => attribute.values.map do |value|
                  {
                    "id" => value.gid,
                    "name" => value.name,
                  }
                end,
              }
              result.delete("extended_name") unless attribute.extended?
              result
            end
          end
        end
      end
    end
  end
end
