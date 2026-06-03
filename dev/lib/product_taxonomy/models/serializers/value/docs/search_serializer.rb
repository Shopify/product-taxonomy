# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Docs
        module SearchSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Value.all_values_sorted.map { |value| serialize(value) }
            end

            # @param [Value] value
            # @return [Hash]
            def serialize(value)
              {
                "searchIdentifier" => value.handle,
                "title" => value.full_name,
                "url" => "?valueHandle=#{value.handle}",
                "value" => {
                  "handle" => value.handle,
                  "name" => value.name,
                  "attribute_handle" => value.primary_attribute&.handle,
                },
              }
            end
          end
        end
      end
    end
  end
end
