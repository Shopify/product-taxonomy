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
          # create all categories
          delayed_children = vertical_json.map do |category_json|
            category = Category.create(
              id: category_json["id"].downcase,
              name: category_json["name"],
              parent_id: category_json["parent_id"],
              property_ids: category_json["attribute_ids"]
            )

            [category, category_json["children_ids"]]
          end

          # assemble the tree
          delayed_children.each do |category, delayed_child_ids|
            next if delayed_child_ids.empty?

            category.child_ids = delayed_child_ids
            category.save!
          end
        end
      end
    end
  end
end
