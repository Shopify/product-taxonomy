# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Dist
        module TxtSerializer
          class << self
            def serialize_all(version:, locale: "en", padding: longest_gid_length)
              header = <<~HEADER
                # Shopify Product Taxonomy - Categories: #{version}
                # Format: {GID} : {Ancestor name} > ... > {Category name}

              HEADER

              categories_txt = ProductTaxonomy::Category
                .all_depth_first
                .map { |category| serialize(category, padding:, locale:) }
                .join("\n")

              header + categories_txt
            end

            # @param category [Category]
            # @param padding [Integer] The padding to use for the GID.
            # @param locale [String] The locale to use for localization.
            # @return [String]
            def serialize(category, padding:, locale: "en")
              "#{category.gid.ljust(padding)} : #{category.full_name(locale:)}"
            end

            private

            def longest_gid_length
              ProductTaxonomy::Category.all.max_by { |c| c.gid.length }.gid.length
            end
          end
        end
      end
    end
  end
end
