# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        module SearchSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Attribute.all.sort_by(&:name).map do |attribute|
                serialize(attribute)
              end
            end

            # @param [Attribute] attribute
            # @return [Hash]
            def serialize(attribute)
              {
                "searchIdentifier" => attribute.handle,
                "title" => attribute.name,
                "url" => "?attributeHandle=#{attribute.handle}",
                "attribute" => {
                  "handle" => attribute.handle,
                },
              }
            end
          end
        end
      end
    end
  end
end
