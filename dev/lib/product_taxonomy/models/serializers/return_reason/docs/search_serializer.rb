# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        module SearchSerializer
          class << self
            def serialize_all
              ProductTaxonomy::ReturnReason.all.map { serialize(_1) }
            end

            # @param [ReturnReason] return_reason
            # @return [Hash]
            def serialize(return_reason)
              {
                "searchIdentifier" => return_reason.handle,
                "title" => return_reason.name,
                "url" => "?returnReasonHandle=#{CGI.escapeURIComponent(return_reason.handle)}",
                "return_reason" => {
                  "handle" => return_reason.handle,
                  "name" => return_reason.name,
                  "description" => return_reason.description,
                },
              }
            end
          end
        end
      end
    end
  end
end
