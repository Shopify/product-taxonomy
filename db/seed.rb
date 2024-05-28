# frozen_string_literal: true

require_relative "../config/application"

module DB
  class Seed
    class << self
      def from_data_files!(cli)
        seed = new(verbose: cli.options.verbose)
        seed.import_taxonomy!(
          values_data: cli.parse_yaml("data/values.yml"),
          attributes_data: cli.parse_yaml("data/attributes.yml"),
          verticals_data: cli.glob("data/categories/*.yml").map { cli.parse_yaml(_1) },
        )
        seed.import_integrations!(
          integrations_data: cli.parse_yaml("data/integrations/integrations.yml"),
          mapping_rule_files: cli.glob("data/integrations/*/*/mappings/*_shopify.yml"),
        )
        seed
      end
    end

    def initialize(verbose: false)
      @verbose = !!verbose
    end

    def import_taxonomy!(values_data:, attributes_data:, verticals_data:)
      vputs("→ Importing taxonomy")

      vputs("  → Attributes and values")
      Attribute.insert_all_from_data(attributes_data["base_attributes"])
      Value.insert_all_from_data(values_data)
      AttributesValue.insert_all_from_data(attributes_data["base_attributes"])

      inserted_attributes = Attribute.insert_all_from_data(
        attributes_data["extended_attributes"],
        returning: ["id", "base_friendly_id"],
      )
      AttributesValue.insert_all_from_data(inserted_attributes)
      vputs("    ✓ Imported #{Attribute.count} attributes and #{Value.count} values")

      vputs("  → #{verticals_data.count} category verticals")
      verticals_data.each do |vertical_data|
        vputs("    → #{vertical_data.first.fetch("name")}")
        Category.insert_all_from_data(vertical_data)
        CategoriesAttribute.insert_all_from_data(vertical_data)
      end
      vputs("    ✓ Imported #{Category.verticals.count} verticals with #{Category.count} categories")

      vputs("  → Validating taxonomy...")
      if values_data.size != Value.count
        vputs("  ✗ Import failed. Values count mismatch")
        exit(1)
      elsif attributes_data["base_attributes"].size != Attribute.base.count
        vputs("  ✗ Import failed. Base attributes count mismatch")
        exit(1)
      elsif attributes_data["extended_attributes"].size != Attribute.extended.count
        vputs("  ✗ Import failed. Extended attributes count mismatch")
        exit(1)
      elsif verticals_data.size != Category.verticals.count
        vputs("  ✗ Import failed. Verticals count mismatch")
        exit(1)
      elsif verticals_data.sum(&:size) != Category.count
        vputs("  ✗ Import failed. Categories count mismatch")
        exit(1)
      end
      [Value, Attribute, AttributesValue, Category, CategoriesAttribute].each do |model|
        if model.count.zero?
          vputs("  ✗ Import failed. No #{model.name.pluralize} found")
          exit(1)
        elsif model.all.any?(:invalid?)
          vputs("  ✗ Import failed. Invalid #{model.name.pluralize} found")
          exit(1)
        else
          vputs("    ✓ #{model.name.pluralize} valid")
        end
      end
      vputs("  ✓ Taxonomy import successful")
    end

    def import_integrations!(integrations_data:, mapping_rule_files:)
      vputs("→ Importing integrations")

      vputs("  → #{integrations_data.count} mapping integrations")
      Integration.insert_all_from_data(integrations_data)
      mapping_rules_from(mapping_rule_files)
      vputs("    ✓ Imported #{Integration.count} integrations with #{MappingRule.count} mapping rules")

      vputs("  → Validating integrations...")
      if integrations_data.size != Integration.count
        vputs("  ✗ Import failed. Integrations count mismatch")
        exit(1)
      end
      [Integration, MappingRule, Product].each do |model|
        if model.count.zero?
          vputs("  ✗ Import failed. No #{model.name.pluralize} found")
          exit(1)
        elsif model.all.any?(:invalid?)
          vputs("  ✗ Import failed. Invalid #{model.name.pluralize} found")
          exit(1)
        else
          vputs("    ✓ #{model.name.pluralize} valid")
        end
      end
      vputs("  ✓ Integration import successful")
    end

    private

    # once serializers are complete, this likely can be inlined
    def mapping_rules_from(data)
      mapping_rules = []
      data.each do |file|
        vputs("    → #{file}")
        from_shopify = File.basename(file, ".*").split("_")[0] == "from"
        integration_name = Pathname.new(file).each_filename.to_a[-4]
        integration_id = Integration.find_by(name: integration_name)&.id
        next if integration_id.nil?

        raw_mappings = YAML.load_file(file)
        full_name_file_dir = File.expand_path("..", File.dirname(file))
        full_names = {}
        YAML.load_file(File.join(full_name_file_dir, "full_names.yml")).each do |category|
          full_names[Category.gid(category["id"])] = category["full_name"]
        end
        input_type = "ShopifyProduct"
        output_type = "#{integration_name.capitalize}Product"
        unless from_shopify
          input_type, output_type = output_type, input_type
        end
        rules = raw_mappings["rules"]
        rules.each do |rule|
          input_product_category_id = rule["input"]["product_category_id"]
          input_product_category_full_name = if from_shopify
            Category.find_by(id: input_product_category_id)&.full_name
          else
            if input_product_category_id.is_a?(Integer)
              input_product_category_id = Category.gid(input_product_category_id)
            end
            full_names[input_product_category_id]
          end
          input_product = Product.find_or_create_from_data!(
            rule["input"],
            type: input_type,
            full_name: input_product_category_full_name,
          )
          output_product_category_id = Array(rule["output"]["product_category_id"]).first
          output_product_category_full_name = if from_shopify
            unless output_product_category_id.starts_with?("gid")
              output_product_category_id = Category.gid(output_product_category_id)
            end
            full_names[output_product_category_id]
          else
            Category.find_by(id: output_product_category_id)&.full_name
          end
          output_product = Product.find_or_create_from_data!(
            rule["output"],
            type: output_type,
            full_name: output_product_category_full_name,
          )

          mapping_rules << {
            integration_id: integration_id,
            from_shopify: from_shopify,
            input_id: input_product.id,
            output_id: output_product.id,
            input_type: input_type,
            output_type: output_type,
            input_version: raw_mappings["input_taxonomy"],
            output_version: raw_mappings["output_taxonomy"],
          }
        end
      end
      MappingRule.insert_all(mapping_rules)
    end

    def vputs(...)
      puts(...) if @verbose
    end
  end
end
