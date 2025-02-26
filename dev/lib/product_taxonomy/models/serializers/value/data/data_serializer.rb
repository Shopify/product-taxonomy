# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Data
        module DataSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Value.all.sort_by(&:id).map { serialize(_1) }
            end

            # @param [Value] value
            # @return [Hash]
            def serialize(value)
              {
                "id" => value.id,
                "name" => value.name,
                "friendly_id" => value.friendly_id,
                "handle" => value.handle,
              }
            end
          end
        end
      end
    end
  end
end
