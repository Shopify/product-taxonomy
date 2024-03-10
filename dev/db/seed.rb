require_relative '../application'

module DB
  class Seed
    class << self
      def attributes_from(data)
        puts "Importing values"
        data.each do |property_json|
          property_json['values'].each do |property_json|
            property_value = Serializers::Data::PropertyValueSerializer.deserialize(property_json)
            by_id = PropertyValue.find_by(id: property_value.id)

            if by_id.nil?
              property_value.save!
            elsif by_id.name != property_value.name
              puts "  ⨯ Failed to import value: #{property_value.name} <#{property_value.id}> already exists as #{by_id.name} <#{by_id.id}>"
            end
          end
        end
        puts "✓ Imported #{PropertyValue.count} values"

        puts "Importing properties"
        data.each do |json|
          Serializers::Data::PropertySerializer.deserialize(json).save!
        end
        puts "✓ Imported #{Property.count} properties"
      end

      def categories_from(data)
        puts "Importing #{data.count} category verticals"
        data.each do |vertical_json|
          puts "  → #{vertical_json.first.fetch("name")}"
          vertical_json.each do |category_json|
            unless Serializers::Data::CategorySerializer.deserialize(category_json.except("children")).save
              puts "  ⨯ Failed to import category: #{category_json["name"]} <#{category_json["id"]}>"
            end
          end
        end
        puts "✓ Imported #{Category.count} categories"
      end
    end
  end
end
