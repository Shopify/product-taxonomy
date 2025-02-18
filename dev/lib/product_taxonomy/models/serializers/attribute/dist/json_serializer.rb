# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Dist
        class JsonSerializer
          class << self
            def serialize_all(version:, locale: "en")
              {
                "version" => version,
                "attributes" => ProductTaxonomy::Attribute.sorted_base_attributes.map { serialize(_1, locale:) },
              }
            end

            # @param attribute [Attribute]
            # @param locale [String] The locale to use for localized attributes.
            # @return [Hash]
            def serialize(attribute, locale: "en")
              {
                "id" => attribute.gid,
                "name" => attribute.name(locale:),
                "handle" => attribute.handle,
                "description" => attribute.description(locale:),
                "extended_attributes" => attribute.extended_attributes.sort_by(&:name).map do |ext_attr|
                  {
                    "name" => ext_attr.name(locale:),
                    "handle" => ext_attr.handle,
                  }
                end,
                "values" => attribute.sorted_values(locale:).map do |value|
                  Serializers::Value::Dist::JsonSerializer.serialize(value, locale:)
                end,
              }
            end
          end
        end
      end
    end
  end
end
