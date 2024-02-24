require 'json'

module Serializers
  module Dist
    class JSON
      def initialize(verticals:, properties:, version:)
        @verticals = verticals
        @properties = properties
        @version = version
      end

      def taxonomy
        output = {
          version: @version,
          verticals: @verticals.map(&method(:serialize_vertical)),
          attributes: @properties.map(&method(:serialize_property)),
        }
        ::JSON.pretty_generate(output)
      end

      def categories
        output = {
          version: @version,
          verticals: @verticals.map(&method(:serialize_vertical)),
        }
        ::JSON.pretty_generate(output)
      end

      def attributes
        output = {
          version: @version,
          attributes: @properties.map(&method(:serialize_property)),
        }
        ::JSON.pretty_generate(output)
      end

      private

      def serialize_vertical(vertical)
        {
          name: vertical.name,
          prefix: vertical.id.downcase,
          categories: vertical.descendants_and_self.map(&method(:serialize_category)),
        }
      end

      def serialize_category(category)
        {
          id: category.gid,
          level: category.level,
          name: category.name,
          full_name: category.full_name,
          parent_id: category.parent&.gid,
          attributes: category.properties.map(&method(:serialize_nested)),
          children: category.children.map(&method(:serialize_nested)),
          ancestors: category.ancestors.map(&method(:serialize_nested)),
        }
      end

      def serialize_property(property)
        {
          id: property.gid,
          name: property.name,
          values: property.property_values.map(&method(:serialize_nested)),
        }
      end

      def serialize_nested(connection)
        {
          id: connection.gid,
          name: connection.name
        }
      end
    end
  end
end
