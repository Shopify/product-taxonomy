module Serializers
  module Dist
    class Text
      def initialize(verticals:, version:)
        @verticals = verticals
        @version = version
      end

      def categories
        header = "# Shopify Product Taxonomy: #{@version}"
        gid_padd = Category.reorder("LENGTH(id) desc").first.gid.size
        @verticals
          .flat_map(&:descendants_and_self)
          .map { serialize_category(_1, gid_padd:) }
          .unshift(header)
          .join("\n")
      end

      private

      def serialize_category(category, gid_padd:)
        "#{category.gid.ljust(gid_padd)} : #{category.full_name}"
      end
    end
  end
end
