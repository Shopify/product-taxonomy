# frozen_string_literal: true

module Distribution
  class VerticalSerializer
    class << self
      def as_json_collection(verticals, version:)
        {
          "version" => version,
          "verticals" => verticals.map { as_json(_1) },
        }
      end

      def as_json(vertical)
        {
          "name" => vertical.name,
          "prefix" => vertical.id.downcase,
          "categories" => vertical.descendants_and_self.map { CategorySerializer.as_json(_1) },
        }
      end

      def to_txt_collection(verticals, version:)
        header = <<~HEADER
          # Shopify Product Taxonomy - Categories: #{version}
          # Format: {GID} : {Ancestor name} > ... > {Category name}
        HEADER
        padding = Category.reorder("LENGTH(id) desc").first.gid.size
        [
          header,
          *verticals.map { to_txt(_1, padding:) },
        ].join("\n")
      end

      def to_txt(vertical, padding:)
        vertical
          .descendants_and_self
          .map { CategorySerializer.to_txt(_1, padding:) }
          .join("\n")
      end
    end
  end
end
