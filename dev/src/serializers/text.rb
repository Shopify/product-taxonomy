module Serializers
  class Text
    def initialize(taxonomy, version)
      @taxonomy = taxonomy
      @version = version
    end

    def categories
      header = "# Shopify Product Taxonomy: #{@version}"
      @taxonomy.categories.map(&:serialize_as_txt).unshift(header).join("\n")
    end
  end
end
