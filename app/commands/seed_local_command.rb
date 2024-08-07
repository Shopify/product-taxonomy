# frozen_string_literal: true

class SeedLocalCommand < ApplicationCommand
  usage do
    no_command
  end

  option :targets do
    desc "Which systems to sync. Syncs all if not specified."
    short "-t"
    long "--target string"
    arity zero_or_more
    permit ["taxonomy", "integrations"]
  end

  option :version do
    desc "Distribution version"
    short "-V"
    long "--version string"
  end

  def execute
    setup_options
    frame("Seeding database") do
      import_taxonomy if params[:targets].include?("taxonomy")
      import_integrations if params[:targets].include?("integrations")
      validate_import
    end
  end

  private

  def setup_options
    params[:targets] ||= ["taxonomy", "integrations"]
    params[:version] ||= sys.read_file("VERSION").strip
  end

  def import_taxonomy
    frame("Importing taxonomy") do
      import_attributes_and_values
      import_categories
    end
  end

  def import_attributes_and_values
    spinner("Importing attributes and values") do |sp|
      Attribute.insert_all_from_data(attributes_data["base_attributes"])
      Value.insert_all_from_data(values_data, attributes_data["base_attributes"])
      AttributesValue.insert_all_from_data(attributes_data["base_attributes"])

      inserted_attributes = Attribute.insert_all_from_data(
        attributes_data["extended_attributes"],
        returning: ["id", "base_friendly_id"],
      )
      AttributesValue.insert_all_from_data(inserted_attributes)
      sp.update_title("Imported #{Attribute.count} attributes and #{Value.count} values")
    end
  end

  def import_categories
    spinner("Importing categories") do |sp|
      verticals_data.each do |vertical_data|
        logger.debug("Importing vertical: #{vertical_data.first.fetch("name")}")
        Category.insert_all_from_data(vertical_data)
        CategoriesAttribute.insert_all_from_data(vertical_data)
      end
      sp.update_title("Imported #{Category.verticals.count} verticals with #{Category.count} categories")
    end
  end

  def import_integrations
    frame("Importing integrations") do
      spinner("Importing integrations and mapping rules") do |sp|
        Integration.insert_all_from_data(integrations_data)
        sp.update_title("Imported #{Integration.count} integrations")
      end
      spinner("Importing mapping rules") do |sp|
        mapping_rules_from(mapping_rule_files)
        sp.update_title("Imported #{MappingRule.count} mapping rules")
      end
    end
  end

  def validate_import
    frame("Validating import") do
      validate_counts
      validate_models
    end
  end

  def validate_counts
    spinner("Validating counts") do |sp|
      errors = []
      errors << "Values count mismatch" if values_data.size != Value.count
      errors << "Base attributes count mismatch" if attributes_data["base_attributes"].size != Attribute.base.count
      errors << "Extended attributes count mismatch" if attributes_data["extended_attributes"].size != Attribute.extended.count
      errors << "Verticals count mismatch" if verticals_data.size != Category.verticals.count
      errors << "Categories count mismatch" if verticals_data.sum(&:size) != Category.count
      errors << "Integrations count mismatch" if integrations_data.size != Integration.count

      if errors.empty?
        sp.update_title("All counts validated successfully")
      else
        logger.fatal(errors.join(", "))
        exit(1)
      end
    end
  end

  def validate_models
    [
      Value,
      Attribute,
      AttributesValue,
      Category,
      CategoriesAttribute,
      Integration,
      MappingRule,
      Product,
    ].each do |model|
      spinner("Validating #{model.name.pluralize}") do |sp|
        if model.count.zero?
          logger.fatal("No #{model.name.pluralize} found")
          exit(1)
        elsif model.all.any?(:invalid?)
          logger.fatal("Invalid #{model.name.pluralize} found")
          exit(1)
        else
          sp.update_title("#{model.name.pluralize} valid")
        end
      end
    end
  end

  # TODO: this needs to be simplified
  def mapping_rules_from(data)
    mapping_rules = []
    shopify_taxonomy_version = "shopify/" + params[:version]

    data.each do |file|
      logger.debug("→ #{file}")
      from_shopify = File.basename(file, ".*").split("_")[0] == "from"
      integration_name = Pathname.new(file).each_filename.to_a[-4]
      integration_id = Integration.find_by(name: integration_name)&.id
      next if integration_id.nil?

      raw_mappings = sys.parse_yaml(file)
      full_name_file_dir = File.expand_path("..", File.dirname(file))
      full_names = {}
      sys.parse_yaml(File.join(full_name_file_dir, "full_names.yml")).each do |category|
        full_names[Category.gid(category["id"])] = category["full_name"]
      end
      input_type = "ShopifyProduct"
      output_type = "#{integration_name.capitalize}Product"
      unless from_shopify
        input_type, output_type = output_type, input_type
      end
      rules = raw_mappings["rules"]
      input_taxonomy = if raw_mappings["input_taxonomy"] == "shopify"
        shopify_taxonomy_version
      else
        raw_mappings["input_taxonomy"]
      end

      output_taxonomy = if raw_mappings["output_taxonomy"] == "shopify"
        shopify_taxonomy_version
      else
        raw_mappings["output_taxonomy"]
      end

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
          input_version: input_taxonomy,
          output_version: output_taxonomy,
        }
      end
    end
    MappingRule.insert_all(mapping_rules)
  end

  def values_data
    @values_data ||= sys.parse_yaml("data/values.yml")
  end

  def attributes_data
    @attributes_data ||= sys.parse_yaml("data/attributes.yml")
  end

  def verticals_data
    @verticals_data ||= sys.glob("data/categories/*.yml").map { sys.parse_yaml(_1) }
  end

  def integrations_data
    @integrations_data ||= sys.parse_yaml("data/integrations/integrations.yml")
  end

  def mapping_rule_files
    @mapping_rule_files ||= sys.glob("data/integrations/*/*/mappings/*_shopify.yml")
  end
end
