# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Data
        module DataSerializer
          class << self
            # @return [Array<Hash>] Array of serialized disclosure data
            def serialize_all
              ProductTaxonomy::Disclosure.all.sort_by(&:id).map { serialize(_1) }
            end

            # Keys that only appear on some leaf entries in the hand-authored
            # data file. They are omitted (rather than serialized as nil) so
            # `dump_disclosures` output matches the authored file shape.
            OPTIONAL_KEYS = ["jurisdictions", "display_preferences"].freeze

            # @param disclosure [Disclosure] The disclosure to serialize
            # @return [Hash] Hash containing the disclosure data
            def serialize(disclosure)
              data = {
                "id" => disclosure.id,
                "public_id" => disclosure.public_id,
                "parent_public_id" => disclosure.parent_public_id,
                "name" => disclosure.name,
                "internal_label" => disclosure.internal_label,
                "description" => disclosure.description,
                "jurisdictions" => disclosure.jurisdictions,
                "legal_citation" => disclosure.legal_citation,
                "symbol" => disclosure.symbol,
                "display_requirements" => disclosure.display_requirements,
                "display_preferences" => disclosure.display_preferences,
                "title" => disclosure.title,
                "content" => disclosure.content,
                "source" => disclosure.source,
                "disclosure_attributes" => disclosure.disclosure_attributes,
                "disclosure_attribute_values" => disclosure.disclosure_attribute_values,
              }
              OPTIONAL_KEYS.each { data.delete(_1) if data[_1].nil? }
              data
            end
          end
        end
      end
    end
  end
end
