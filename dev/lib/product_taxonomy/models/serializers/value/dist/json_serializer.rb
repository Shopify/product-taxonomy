# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Value
      module Dist
        class JsonSerializer
          class << self
            def serialize_all(version:, locale: "en")
              {
                "version" => version,
                "values" => ProductTaxonomy::Value.all_values_sorted.map { serialize(_1, locale:) },
              }
            end

            # @param value [Value]
            # @param locale [String] The locale to use for localization.
            # @return [Hash]
            def serialize(value, locale: "en")
              {
                "id" => value.gid,
                "name" => value.name(locale:),
                "handle" => value.handle,
              }
            end
          end
        end
      end
    end
  end
end
