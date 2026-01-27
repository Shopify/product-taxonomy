# frozen_string_literal: true

require "yaml"

module ProductTaxonomy
  class Loader
    class << self
      def load(values_path:, attributes_path:, categories_glob:, return_reasons_path: nil)
        return if ProductTaxonomy::Category.all.any?

        begin
          ProductTaxonomy::Value.load_from_source(YAML.load_file(values_path))
          ProductTaxonomy::Attribute.load_from_source(YAML.load_file(attributes_path))

          if return_reasons_path && File.exist?(return_reasons_path)
            ProductTaxonomy::ReturnReason.load_from_source(YAML.load_file(return_reasons_path))
          end

          categories_source_data = categories_glob.each_with_object([]) do |file, array|
            array.concat(YAML.safe_load_file(file))
          end
          ProductTaxonomy::Category.load_from_source(categories_source_data)
        rescue Errno::ENOENT => e
          raise ArgumentError, "File not found: #{e.message}"
        rescue Psych::SyntaxError => e
          raise ArgumentError, "Invalid YAML: #{e.message}"
        end

        # Run validations that can only be run after the taxonomy has been loaded.
        ProductTaxonomy::Value.all.each { |model| model.validate!(:taxonomy_loaded) }
      end
    end
  end
end
