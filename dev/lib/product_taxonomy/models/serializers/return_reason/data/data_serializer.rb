# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        module DataSerializer
          class << self
            def serialize_all
              ProductTaxonomy::ReturnReason.all.sort_by(&:id).map { serialize(_1) }
            end

            # @param [ReturnReason] return_reason
            # @return [Hash]
            def serialize(return_reason)
              {
                "id" => return_reason.id,
                "name" => return_reason.name,
                "description" => return_reason.description,
                "friendly_id" => return_reason.friendly_id,
                "handle" => return_reason.handle,
              }
            end
          end
        end
      end
    end
  end
end




