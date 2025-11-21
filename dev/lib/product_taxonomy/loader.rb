# frozen_string_literal: true

require "yaml"

module ProductTaxonomy
  class Loader
    class << self
      def load(values_path, attributes_path, categories_glob)
          return if ProductTaxonomy::Category.all.any?

          load_values(values_path)
          load_attributes(attributes_path)
          load_categories(categories_glob)
          validate_taxonomy

          {
            categories: ProductTaxonomy::Category.all,
            attributes: ProductTaxonomy::Attribute.all,
            values: ProductTaxonomy::Value.all,
            verticals: ProductTaxonomy::Category.verticals,
          }
        end

      private

      def load_values(values_path)
        ProductTaxonomy::Value.load_from_source(YAML.load_file(values_path))
      end

      def load_attributes(attributes_path)
        ProductTaxonomy::Attribute.load_from_source(YAML.load_file(attributes_path))
      end

      def load_categories(categories_glob)
        categories_source_data = categories_glob.each_with_object([]) do |file, array|
          array.concat(YAML.safe_load_file(file))
        end
        ProductTaxonomy::Category.load_from_source(categories_source_data)
      end

      def validate_taxonomy
        # Run validations that can only be run after the taxonomy has been loaded.
        ProductTaxonomy::Value.all.each { |model| model.validate!(:taxonomy_loaded) }
      end
    end
  end
end

