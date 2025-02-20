# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Dist
        class TxtSerializer
          class << self
            def serialize_all(version:, locale: "en", padding: longest_gid_length)
              header = <<~HEADER
                # Shopify Product Taxonomy - Attributes: #{version}
                # Format: {GID} : {Attribute name}

              HEADER

              attributes_txt = ProductTaxonomy::Attribute
                .sorted_base_attributes
                .map { serialize(_1, padding:, locale:) }
                .join("\n")

              header + attributes_txt
            end

            # @param attribute [Attribute]
            # @param padding [Integer] The padding to use for the GID.
            # @param locale [String] The locale to use for localized attributes.
            # @return [String]
            def serialize(attribute, padding: 0, locale: "en")
              "#{attribute.gid.ljust(padding)} : #{attribute.name(locale:)}"
            end

            private

            def longest_gid_length
              ProductTaxonomy::Attribute.all.filter_map { _1.extended? ? nil : _1.gid.length }.max
            end
          end
        end
      end
    end
  end
end
