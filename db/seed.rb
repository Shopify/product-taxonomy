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

    private

    def vputs(...)
      puts(...) if @verbose
    end
  end
end
