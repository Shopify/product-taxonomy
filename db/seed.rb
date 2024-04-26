# frozen_string_literal: true

require_relative "../application"

module DB
  class Seed
    def initialize(verbose: false)
      @verbose = verbose
    end

    def values_from(data)
      vputs("Importing values")
      property_values = SourceData::PropertyValueSerializer.deserialize_for_insert_all(data)
      PropertyValue.insert_all(property_values)
      vputs("✓ Imported #{PropertyValue.count} values")
    end

    def attributes_from(data)
      base_attributes = data["base_attributes"]
      extended_attributes = data["extended_attributes"]
      vputs("Importing base properties")
      base_properties = SourceData::BasePropertySerializer.deserialize_for_insert_all(base_attributes)
      Property.insert_all(base_properties)
      vputs("→ and their value relationships")
      base_property_joins = SourceData::BasePropertySerializer.deserialize_for_join_insert_all(base_attributes)
      PropertiesPropertyValue.insert_all!(base_property_joins)
      vputs("✓ Imported #{Property.count} properties")

      vputs("Importing extended properties")
      extended_properties = SourceData::ExtendedPropertySerializer.deserialize_for_insert_all(extended_attributes)
      inserted_properties = Property.insert_all(extended_properties, returning: ["id", "base_friendly_id"])
      vputs("→ and their value relationships")
      extended_property_joins = SourceData::ExtendedPropertySerializer.deserialize_for_join_insert_all(inserted_properties)
      PropertiesPropertyValue.insert_all(extended_property_joins)
      vputs("✓ Imported #{PropertiesPropertyValue.count} property ↔ value relationships")
    end

    def categories_from(data)
      vputs("Importing #{data.count} category verticals")
      data.each do |vertical_json|
        vputs("  → #{vertical_json.first.fetch("name")}")
        categories = SourceData::CategorySerializer.deserialize_for_insert_all(vertical_json)
        Category.insert_all(categories)
      end
      vputs("✓ Imported #{Category.count} categories")

      vputs("Importing category relationships")
      data.each do |vertical_json|
        joins = SourceData::CategorySerializer.deserialize_for_join_insert_all(vertical_json)
        CategoriesProperty.insert_all(joins)
      end
      vputs("✓ Imported #{CategoriesProperty.count} category ↔ property relationships")
    end

    def integrations_from(data)
      vputs("Importing integrations")
      integrations = data.map { { name: _1["name"], available_versions: _1["available_versions"] } }
      Integration.insert_all(integrations)
      vputs("✓ Imported #{Integration.count} integrations")
    end

    def mapping_rules_from(data)
      vputs("Importing mapping rules")
      mapping_rules = []
      data.each do |file|
        vputs("Importing mapping rules from #{file}")
        from_shopify = File.basename(file, ".*").split("_")[0] == "from"
        integration_name = Pathname.new(file).each_filename.to_a[-4]
        integration_id = Integration.find_by(name: integration_name)&.id
        next if integration_id.nil?

        raw_mappings = YAML.load_file(file)
        input_type = "ShopifyProduct"
        output_type = "#{integration_name.capitalize}Product"
        unless from_shopify
          input_type, output_type = output_type, input_type
        end
        rules = raw_mappings["rules"]
        rules.each do |rule|
          input_product_hash = SourceData::ProductSerializer.deserialize(rule["input"], input_type).payload
          input_product = Product.find_or_create_by!(type: input_type, payload: input_product_hash)
          output_product_hash = SourceData::ProductSerializer.deserialize(rule["output"], output_type).payload
          output_product = Product.find_or_create_by!(type: output_type, payload: output_product_hash)

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
      vputs("✓ Imported all #{MappingRule.count} mapping rules")
    end

    private

    def vputs(...)
      puts(...) if @verbose
    end
  end
end
