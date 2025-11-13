# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        class LocalizationsSerializer
          class << self
            # @param locale [String]
            # @return [Hash]
            def serialize_all(locale: "en")
              {
                locale => {
                  "return_reasons" => ProductTaxonomy::ReturnReason.all.sort_by(&:friendly_id).each_with_object({}) do |return_reason, hash|
                    hash[return_reason.friendly_id] = serialize(return_reason, locale:)
                  end,
                },
              }
            end

            # @param return_reason [ReturnReason]
            # @param locale [String]
            # @return [Hash]
            def serialize(return_reason, locale: "en")
              {
                "name" => return_reason.name(locale:),
                "description" => return_reason.description(locale:),
              }
            end
          end
        end
      end
    end
  end
end




