# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class TxtSerializer
          class << self
            def serialize_all(version:, locale: "en", padding: longest_gid_length)
              header = <<~HEADER
                # Shopify Product Taxonomy - Return Reasons: #{version}
                # Format: {GID} : {Return reason name}

              HEADER

              return_reasons_txt = ProductTaxonomy::ReturnReason
                .all
                .sort_by(&:name)
                .map { serialize(_1, padding:, locale:) }
                .join("\n")

              header + return_reasons_txt
            end

            # @param return_reason [ReturnReason]
            # @param padding [Integer] The padding to use for the GID.
            # @param locale [String] The locale to use for localized return reasons.
            # @return [String]
            def serialize(return_reason, padding: 0, locale: "en")
              "#{return_reason.gid.ljust(padding)} : #{return_reason.name(locale:)}"
            end

            private

            def longest_gid_length
              ProductTaxonomy::ReturnReason.all.map { _1.gid.length }.max || 0
            end
          end
        end
      end
    end
  end
end




