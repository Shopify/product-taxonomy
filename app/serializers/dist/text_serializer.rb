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
      header = <<~HEADER
        # Shopify Product Taxonomy - Categories: #{@version}
        # Format: {GID} : {Ancestor name} > ... > {Category name}
      HEADER
      gid_padd = Category.reorder("LENGTH(id) desc").first.gid.size
      @verticals
        .flat_map(&:descendants_and_self)
        .map { serialize_category(_1, gid_padd:) }
        .unshift(header)
        .join("\n")
    end

    def attributes
      header = <<~HEADER
        # Shopify Product Taxonomy - Attributes: #{@version}
        # Format: {GID} : {Attribute name}
      HEADER
      gid_padd = Property.reorder("LENGTH(id) desc").first.gid.size
      @properties
        .map { serialize_property(_1, gid_padd:) }
        .unshift(header)
        .join("\n")
    end

    def values
      header = <<~HEADER
        # Shopify Product Taxonomy - Attribute Values: #{@version}
        # Format: {GID} : {Value name} [{Attribute name}]
      HEADER
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
      "#{value.gid.ljust(gid_padd)} : #{value.full_name}"
    end
  end
end
