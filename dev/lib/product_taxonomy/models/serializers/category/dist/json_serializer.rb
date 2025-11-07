# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Dist
        module JsonSerializer
          class << self
            def serialize_all(version:, locale: "en")
              {
                "version" => version,
                "verticals" => ProductTaxonomy::Category.verticals.map do |vertical|
                  {
                    "name" => vertical.name(locale:),
                    "prefix" => vertical.id,
                    "categories" => vertical.descendants_and_self.map { |category| serialize(category, locale:) },
                  }
                end,
              }
            end

            # @param category [Category]
            # @param locale [String] The locale to use for localization.
            # @return [Hash]
            def serialize(category, locale: "en")
              {
                "id" => category.gid,
                "level" => category.level,
                "name" => category.name(locale:),
                "full_name" => category.full_name(locale:),
                "parent_id" => category.parent&.gid,
                "attributes" => category.attributes.map do |attr|
                  {
                    "id" => attr.gid,
                    "name" => attr.name(locale:),
                    "handle" => attr.handle,
                    "description" => attr.description(locale:),
                    "extended" => attr.is_a?(ExtendedAttribute),
                  }
                end,
                "return_reasons" => category.return_reasons.map do |return_reason|
                  {
                    "id" => return_reason.gid,
                    "name" => return_reason.name(locale:),
                    "handle" => return_reason.handle,
                    "description" => return_reason.description(locale:),
                  }
                end,
                "children" => category.children.map do |child|
                  {
                    "id" => child.gid,
                    "name" => child.name(locale:),
                  }
                end,
                "ancestors" => category.ancestors.map do |ancestor|
                  {
                    "id" => ancestor.gid,
                    "name" => ancestor.name(locale:),
                  }
                end,
              }
            end
          end
        end
      end
    end
  end
end
