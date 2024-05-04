# frozen_string_literal: true

module Distribution
  class PropertyValueSerializer
    class << self
      def as_json_collection(values, version:)
        {
          "version" => version,
          "values" => values.map { as_json(_1) },
        }
      end

      def as_json(value)
        {
          "id" => value.gid,
          "name" => value.name,
          "handle" => value.handle,
        }
      end

      def as_simple_json(value)
        {
          "id" => value.gid,
          "name" => value.name,
          "handle" => value.handle,
        }
      end

      def to_txt_collection(values, version:)
        header = <<~HEADER
          # Shopify Product Taxonomy - Attribute Values: #{version}
          # Format: {GID} : {Value name} [{Attribute name}]
        HEADER
        padding = PropertyValue.reorder("LENGTH(id) desc").first.gid.size
        [
          header,
          *values.map { to_txt(_1, padding:) },
        ].join("\n")
      end

      def to_txt(value, padding:)
        "#{value.gid.ljust(padding)} : #{value.full_name}"
      end
    end
  end
end
