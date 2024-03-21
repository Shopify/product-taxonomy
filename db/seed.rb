# frozen_string_literal: true

require_relative "../application"

module DB
  class Seed
    class << self
      def attributes_from(data)
        puts "Importing values"
        raw_values = data.flat_map { _1.fetch("values") }
        values = Serializers::Data::PropertyValueSerializer.deserialize_for_insert_all(raw_values)
        PropertyValue.insert_all(values)
        puts "✓ Imported #{PropertyValue.count} values"

        puts "Importing properties"
        properties = Serializers::Data::PropertySerializer.deserialize_for_insert_all(data)
        Property.insert_all(properties)
        puts "✓ Imported #{Property.count} properties"

        puts "Importing property ↔ value relationships"
        joins = Serializers::Data::PropertySerializer.deserialize_for_join_insert_all(data)
        PropertiesPropertyValue.insert_all(joins)
        puts "✓ Imported #{PropertiesPropertyValue.count} property ↔ value relationships"
      end

      def categories_from(data)
        puts "Importing #{data.count} category verticals"
        data.each do |vertical_json|
          puts "  → #{vertical_json.first.fetch("name")}"
          categories = Serializers::Data::CategorySerializer.deserialize_for_insert_all(vertical_json)
          Category.insert_all(categories)
        end
        puts "✓ Imported #{Category.count} categories"

        puts "Importing category relationships"
        data.each do |vertical_json|
          joins = Serializers::Data::CategorySerializer.deserialize_for_join_insert_all(vertical_json)
          CategoriesProperty.insert_all(joins)
        end
        puts "✓ Imported #{CategoriesProperty.count} category ↔ property relationships"
      end
    end
  end
end
