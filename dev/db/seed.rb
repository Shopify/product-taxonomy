require_relative '../application'

module DB
  class Seed
    class << self
      def attributes_from(data)
        puts "Importing properties and values"
        data.each do |json|
          Serializers::Data::PropertySerializer.deserialize(json).save!
        end
        puts "✓ Imported #{Property.count} properties"
        puts "✓ Imported #{PropertyValue.count} values"
      end

      def categories_from(data)
        puts "Importing #{data.count} category verticals"
        data.each do |vertical_json|
          current_vertical = vertical_json.first.fetch("name")
          puts "  → #{current_vertical}"

          # create all categories
          failed_category_ids = []
          delayed_children = vertical_json.filter_map do |category_json|
            begin
              category = Serializers::Data::CategorySerializer.deserialize(category_json.except("children_ids"))
              category.save!
            rescue => _e
              puts "  ⨯ Failed to import category: #{category_json["name"]} <#{category_json["id"]}>"
              failed_category_ids << category_json["id"]
              next
            end

            [category, category_json["children_ids"]]
          end

          # assemble the tree
          delayed_children.each do |category, delayed_child_ids|
            next if delayed_child_ids.empty?

            category.child_ids = delayed_child_ids - failed_category_ids
            category.save!
          end
        end
        puts "✓ Imported #{Category.count} categories"
      end
    end
  end
end
