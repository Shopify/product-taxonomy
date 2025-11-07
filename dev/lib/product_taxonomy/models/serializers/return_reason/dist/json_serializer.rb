# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class JsonSerializer
          class << self
            # @param return_reason [ReturnReason] The return reason to serialize
            # @param locale [String] The locale to use for localized return reasons
            # @return [Hash] A hash containing the serialized return reason data
            def serialize_all(version:, locale: "en")
              {
                "version" => version,
                "return_reasons" => ProductTaxonomy::ReturnReason.all.sort_by(&:name).map { serialize(_1, locale:) },
              }
            end

            # @param return_reason [ReturnReason]
            # @param locale [String] The locale to use for localized return reasons.
            # @return [Hash]
            def serialize(return_reason, locale: "en")
              {
                "id" => return_reason.gid,
                "name" => return_reason.name(locale:),
                "handle" => return_reason.handle,
                "description" => return_reason.description(locale:),
              }
            end
          end
        end
      end
    end
  end
end

