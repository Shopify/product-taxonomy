module Serializers
  class Text
    attr_reader :taxonomy, :version

    def initialize(taxonomy, version)
      @taxonomy = taxonomy
      @version = version
    end

    def categories
      header = "# Shopify Product Taxonomy: #{Date.today} (#{version})"
      taxonomy.categories.map(&:serialize_as_txt).unshift(header).join("\n")
    end
  end
end
