# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Dist
        class TxtSerializer
          class << self
            # @param version [String] The version to include in the output
            # @param locale [String] The locale to use for localized disclosures
            # @param padding [Integer] The padding to use for the GID
            # @return [String] The formatted text output with header and disclosures
            def serialize_all(version:, locale: "en", padding: longest_gid_length)
              header = <<~HEADER
                # Shopify Product Taxonomy - Disclosures: #{version}
                # Format: {GID} : {Disclosure name}

              HEADER

              disclosures_txt = ProductTaxonomy::Disclosure
                .all
                .map { serialize(_1, padding:, locale:) }
                .join("\n")

              header + disclosures_txt
            end

            # @param disclosure [Disclosure]
            # @param padding [Integer] The padding to use for the GID.
            # @param locale [String] The locale to use for localized disclosures.
            # @return [String]
            def serialize(disclosure, padding: 0, locale: "en")
              "#{disclosure.gid.ljust(padding)} : #{disclosure.name(locale:)}"
            end

            private

            def longest_gid_length
              ProductTaxonomy::Disclosure.all.map { _1.gid.length }.max || 0
            end
          end
        end
      end
    end
  end
end
