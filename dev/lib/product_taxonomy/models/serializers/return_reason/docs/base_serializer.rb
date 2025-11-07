# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        module BaseSerializer
          class << self
            def serialize_all
              ProductTaxonomy::ReturnReason.all.map { serialize(_1) }
            end

            # @param [ReturnReason] return_reason
            # @return [Hash]
            def serialize(return_reason)
              {
                "id" => return_reason.gid,
                "name" => return_reason.name,
                "handle" => return_reason.handle,
                "description" => return_reason.description,
              }
            end
          end
        end
      end
    end
  end
end

