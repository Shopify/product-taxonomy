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
      vputs("Importing properties")
      properties = SourceData::PropertySerializer.deserialize_for_insert_all(data)
      Property.insert_all(properties)
      vputs("✓ Imported #{Property.count} properties")

      vputs("Importing property ↔ value relationships")
      standard_attributes, reference_attributes = data.partition { _1["values_from"].nil? }
      standard_attribute_joins = SourceData::PropertySerializer.deserialize_for_join_insert_all(standard_attributes)
      PropertiesPropertyValue.insert_all!(standard_attribute_joins)

      reference_attribute_joins = SourceData::PropertySerializer.deserialize_for_join_insert_all(reference_attributes)
      PropertiesPropertyValue.insert_all(reference_attribute_joins)

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
      integrations = data.map { { name: _1["name"] } }
      Integration.insert_all(integrations)
      vputs("✓ Imported #{Integration.count} integrations")
    end

    def mapping_rules_from(data)
      vputs("Importing mapping rules")
      mapping_rules = []
      data.each do |file|
        vputs("Importing mapping rules from #{file}")
        from_shopify = File.basename(file, ".*").split("_")[0] == "from"
        integration_name = Pathname.new(file).each_filename.to_a[-3]
        integration_id = Integration.find_by(name: integration_name)&.id
        next if integration_id.nil?

        raw_mappings = YAML.load_file(file)
        input_type = "#{raw_mappings["input_taxonomy"].split("/")[0].capitalize}Product"
        output_type = "#{raw_mappings["output_taxonomy"].split("/")[0].capitalize}Product"
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
