# frozen_string_literal: true

module Dist
  class TextSerializer
    def initialize(verticals:, properties:, values:, version:)
      @verticals = verticals
      @properties = properties
      @values = values
      @version = version
    end

    def categories
      header = "# Shopify Product Taxonomy - Categories: #{@version}"
      gid_padd = Category.reorder("LENGTH(id) desc").first.gid.size
      @verticals
        .flat_map(&:descendants_and_self)
        .map { serialize_category(_1, gid_padd:) }
        .unshift(header)
        .join("\n")
    end

    def attributes
      header = "# Shopify Product Taxonomy - Attributes: #{@version}"
      gid_padd = Property.reorder("LENGTH(id) desc").first.gid.size
      @properties
        .map { serialize_property(_1, gid_padd:) }
        .unshift(header)
        .join("\n")
    end

    def values
      header = "# Shopify Product Taxonomy - Attribute Values: #{@version}"
      gid_padd = PropertyValue.reorder("LENGTH(id) desc").first.gid.size
      @values
        .map { serialize_property_value(_1, gid_padd:) }
        .unshift(header)
        .join("\n")
    end

    private

    def serialize_category(category, gid_padd:)
      "#{category.gid.ljust(gid_padd)} : #{category.full_name}"
    end

    def serialize_property(property, gid_padd:)
      "#{property.gid.ljust(gid_padd)} : #{property.name}"
    end

    def serialize_property_value(value, gid_padd:)
      "#{value.gid.ljust(gid_padd)} : #{value.name}"
    end
  end
end
