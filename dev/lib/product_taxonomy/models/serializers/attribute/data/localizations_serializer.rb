# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Data
        module LocalizationsSerializer
          class << self
            def serialize_all
              attributes = ProductTaxonomy::Attribute.all

              {
                "en" => {
                  "attributes" => attributes.sort_by(&:friendly_id).reduce({}) { _1.merge!(serialize(_2)) },
                },
              }
            end

            # @param [Attribute] attribute
            # @return [Hash]
            def serialize(attribute)
              {
                attribute.friendly_id => {
                  "name" => attribute.name,
                  "description" => attribute.description,
                },
              }
            end
          end
        end
      end
    end
  end
end
