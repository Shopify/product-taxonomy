# frozen_string_literal: true

module Distribution
  class CategorySerializer
    class << self
      def as_json(category)
        {
          "id" => category.gid,
          "level" => category.level,
          "name" => category.name,
          "full_name" => category.full_name,
          "parent_id" => category.parent&.gid,
          "attributes" => category.properties.map { PropertySerializer.as_simple_json(_1) },
          "children" => category.children.map { as_simple_json(_1) },
          "ancestors" => category.ancestors.map { as_simple_json(_1) },
        }
      end

      def as_simple_json(category)
        {
          "id" => category.gid,
          "name" => category.name,
        }
      end

      def to_txt(category, padding:)
        "#{category.gid.ljust(padding)} : #{category.full_name}"
      end
    end
  end
end
