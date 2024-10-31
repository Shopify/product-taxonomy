# frozen_string_literal: true

module ProductTaxonomy
  class Category
    class << self
      def load_from_source(attributes:, file:)
        categories = YAML.safe_load_file(file)
        build_tree(categories:, attributes:)
      end

      def build_tree(categories:, attributes:)
        nodes = {}

        # First pass: Create all nodes
        categories.each do |item|
          node = Category.new(
            id: item["id"],
            name: item["name"],
            attributes: item["attributes"]&.map { attributes[_1] },
          )
          nodes[item["id"]] = node
        end

        # Second pass: Build relationships
        categories.each do |item|
          parent = nodes[item["id"]]
          item["children"]&.each do |child_id|
            child = nodes[child_id]
            parent.add_child(child) if child
          end
        end

        nodes[categories.first["id"]]
      end
    end

    attr_reader :id, :name, :children, :attributes

    def initialize(id:, name:, attributes: [])
      @id = id
      @name = name
      @children = []
      @attributes = attributes
    end

    def add_child(child)
      @children << child
    end

    def to_s
      result = "#{id}: #{name}"
      children.each do |child|
        result += "\n#{child}"
      end
      result
    end
  end
end
