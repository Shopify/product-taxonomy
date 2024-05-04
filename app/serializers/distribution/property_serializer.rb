# frozen_string_literal: true

module Distribution
  class PropertySerializer
    class << self
      def as_json_collection(properties, version:)
        {
          "version" => version,
          "attributes" => properties.map { as_json(_1) },
        }
      end

      def as_json(property)
        {
          "id" => property.gid,
          "name" => property.name,
          "handle" => property.handle,
          "extended_attributes" => property.extended_properties.map do |property|
            {
              "name" => property.name,
              "handle" => property.handle,
            }
          end,
          "values" => property.property_values.map { PropertyValueSerializer.as_simple_json(_1) },
        }
      end

      def as_simple_json(property)
        {
          "id" => property.gid,
          "name" => property.name,
          "handle" => property.handle,
          "extended" => property.extended?,
        }
      end

      def to_txt_collection(properties, version:)
        header = <<~HEADER
          # Shopify Product Taxonomy - Attributes: #{version}
          # Format: {GID} : {Attribute name}
        HEADER
        padding = Property.reorder("LENGTH(id) desc").first.gid.size
        [
          header,
          *properties.map { to_txt(_1, padding:) },
        ].join("\n")
      end

      def to_txt(property, padding:)
        "#{property.gid.ljust(padding)} : #{property.name}"
      end
    end
  end
end
