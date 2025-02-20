# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Dist
        class TxtSerializer
          class << self
            def serialize_all(version:, locale: "en", padding: longest_gid_length)
              header = <<~HEADER
                # Shopify Product Taxonomy - Attribute Values: #{version}
                # Format: {GID} : {Value name} [{Attribute name}]

              HEADER

              header + ProductTaxonomy::Value.all_values_sorted.map { serialize(_1, padding:, locale:) }.join("\n")
            end

            # @param value [Value]
            # @param padding [Integer] The padding to use for the GID.
            # @param locale [String] The locale to use for localization.
            # @return [String]
            def serialize(value, padding: 0, locale: "en")
              "#{value.gid.ljust(padding)} : #{value.full_name(locale:)}"
            end

            private

            def longest_gid_length
              largest_id = ProductTaxonomy::Value.hashed_by(:id).keys.max
              ProductTaxonomy::Value.find_by(id: largest_id).gid.length
            end
          end
        end
      end
    end
  end
end
