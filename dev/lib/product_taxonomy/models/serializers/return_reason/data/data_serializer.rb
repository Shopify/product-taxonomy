# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        module DataSerializer
          class << self
            # @return [Array<Hash>] Array of serialized return data
            def serialize_all
              ProductTaxonomy::ReturnReason.all.sort_by(&:id).map { serialize(_1) }
            end

            # @param return_reason [ReturnReason] The return reason to serialize
            # @return [Hash] Hash containing the return reason data
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




