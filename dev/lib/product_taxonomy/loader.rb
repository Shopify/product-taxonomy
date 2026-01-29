# frozen_string_literal: true

require "yaml"

module ProductTaxonomy
  class Loader
    class << self
      def load(data_path:)
        return if ProductTaxonomy::Category.all.any?

        # Set the module-level data_path so localizations and other files can be accessed
        ProductTaxonomy.data_path = data_path

        values_path = File.join(data_path, "values.yml")
        attributes_path = File.join(data_path, "attributes.yml")
        return_reasons_path = File.join(data_path, "return_reasons.yml")
        categories_glob = Dir.glob(File.join(data_path, "categories", "*.yml"))

        begin
          ProductTaxonomy::Value.load_from_source(YAML.load_file(values_path))
          ProductTaxonomy::Attribute.load_from_source(YAML.load_file(attributes_path))

          if File.exist?(return_reasons_path)
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
