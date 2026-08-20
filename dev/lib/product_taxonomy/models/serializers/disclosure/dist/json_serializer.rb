# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Dist
        class JsonSerializer
          class << self
            # @param version [String] The version to include in the output
            # @param locale [String] The locale to use for localized disclosures
            # @return [Hash] A hash containing the serialized disclosure data
            def serialize_all(version:, locale: "en")
              {
                "version" => version,
                "disclosures" => ProductTaxonomy::Disclosure.all.map { serialize(_1, locale:) },
              }
            end

            # Disclosures form a shallow hierarchy. Records are serialized as a
            # flat list; hierarchy is expressed via `parent_public_id` (matching
            # how categories express hierarchy via `parent_id`). Grouping/root
            # nodes carry nil for leaf-only fields.
            #
            # @param disclosure [Disclosure]
            # @param locale [String] The locale to use for localized disclosures.
            # @return [Hash]
            def serialize(disclosure, locale: "en")
              {
                "id" => disclosure.gid,
                "public_id" => disclosure.public_id,
                "parent_public_id" => disclosure.parent_public_id,
                "name" => disclosure.name(locale:),
                "internal_label" => disclosure.internal_label,
                "description" => disclosure.description(locale:),
                "jurisdictions" => disclosure.jurisdictions,
                "legal_citation" => disclosure.legal_citation,
                "title" => disclosure.title(locale:),
                "content" => disclosure.content(locale:),
                "source" => disclosure.source,
                "symbol" => disclosure.symbol,
                "display_requirements" => disclosure.display_requirements,
                "display_preferences" => disclosure.display_preferences,
                "disclosure_attributes" => disclosure.disclosure_attributes,
                "disclosure_attribute_values" => disclosure.disclosure_attribute_values,
              }
            end
          end
        end
      end
    end
  end
end
