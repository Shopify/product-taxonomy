require_relative '../application'

module DB
  class Seed
    class << self
      def attributes_from(data)
        data.each do |json|
          Property.create(
            id: json["id"],
            name: json["name"],
            property_values: json["values"].map do |v_json|
              PropertyValue.new(id: v_json["id"], name: v_json["name"])
            end
          )
        end
      end

      def categories_from(data)
        data.each do |vertical_json|
          current_vertical = vertical_json.first.fetch("name")
          failed_category_ids = []

          # create all categories
          delayed_children = vertical_json.filter_map do |category_json|
            begin
              category = Category.create(
                id: category_json["id"].downcase,
                name: category_json["name"],
                parent_id: category_json["parent_id"],
                property_ids: category_json["attribute_ids"]
              )
            rescue => _e
              puts "⨯ Failed creating category: #{current_vertical} > #{category_json["name"]} <#{category_json["id"]}>"
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
      end
    end
  end
end
