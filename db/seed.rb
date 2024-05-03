# frozen_string_literal: true

require_relative "../application"

module DB
  class Seed
    def initialize(verbose: false)
      @verbose = verbose
    end

    def values_from(data)
      vputs("Importing values")

      PropertyValue.insert_all(Source::PropertyValueSerializer.unpack_all(data))

      vputs("✓ Imported #{PropertyValue.count} values")
    end

    def attributes_from(data)
      vputs("Importing properties")

      Property.insert_all(Source::PropertySerializer.unpack_all(data["base_attributes"]))
      PropertiesPropertyValue.insert_all!(Source::PropertiesPropertyValueSerializer.unpack_all(data["base_attributes"]))

      inserted_properties = Property.insert_all(
        Source::ExtendedPropertySerializer.unpack_all(data["extended_attributes"]),
        returning: ["id", "base_friendly_id"],
      )
      PropertiesPropertyValue.insert_all!(
        Source::ExtendedPropertiesPropertyValueSerializer.unpack_all(inserted_properties),
      )

      vputs("✓ Imported #{Property.count} properties")
    end

    def categories_from(data)
      vputs("Importing #{data.count} category verticals")

      data.each do |vertical_data|
        vputs("  → #{vertical_data.first.fetch("name")}")
        Category.insert_all(Source::CategorySerializer.unpack_all(vertical_data))
        CategoriesProperty.insert_all(Source::CategoriesPropertySerializer.unpack_all(vertical_data))
      end

      vputs("✓ Imported #{Category.count} categories")
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
          input_product_hash = Source::ProductSerializer.unpack(rule["input"].merge("type" => input_type))
          input_product = Product.find_or_create_by!(type: input_type, payload: input_product_hash)
          output_product_hash = Source::ProductSerializer.unpack(rule["output"].merge("type" => output_type))
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
