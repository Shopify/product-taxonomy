# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Data
        module LocalizationsSerializer
          class << self
            def serialize_all
              values = ProductTaxonomy::Value.all

              {
                "en" => {
                  "values" => values.sort_by(&:friendly_id).reduce({}) { _1.merge!(serialize(_2)) },
                },
              }
            end

            # @param [Value] value
            # @return [Hash]
            def serialize(value)
              {
                value.friendly_id => {
                  "name" => value.name,
                  "context" => value.primary_attribute.name,
                },
              }
            end
          end
        end
      end
    end
  end
end
