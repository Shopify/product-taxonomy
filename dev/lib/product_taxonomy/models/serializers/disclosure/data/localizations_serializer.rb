# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Data
        class LocalizationsSerializer
          class << self
            # @param locale [String] The locale to use for serialization
            # @return [Hash] Hash containing localized disclosure data
            def serialize_all(locale: "en")
              {
                locale => {
                  "disclosures" => ProductTaxonomy::Disclosure.all.sort_by(&:public_id).each_with_object({}) do |disclosure, hash|
                    hash[disclosure.public_id] = serialize(disclosure, locale:)
                  end,
                },
              }
            end

            # @param disclosure [Disclosure] The disclosure to serialize
            # @param locale [String] The locale to use for serialization
            # @return [Hash] Hash containing the localized disclosure fields
            def serialize(disclosure, locale: "en")
              {
                "name" => disclosure.name(locale:),
                "description" => disclosure.description(locale:),
                "title" => disclosure.title(locale:),
                "content" => disclosure.content(locale:),
              }
            end
          end
        end
      end
    end
  end
end
