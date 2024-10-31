# frozen_string_literal: true

require "yaml"
require "benchmark"

require_relative "models/category"
require_relative "models/taxonomy"

module ProductTaxonomy
  class CLI
    class << self
      def start(args)
        Benchmark.bm(7) do |x|
          x.report("Total") do
            taxonomy = Taxonomy.load_from_source
            puts taxonomy
          end
        end
      end

      def build_tree(yaml_data, parent = nil)
        nodes = {}

        # First pass: Create all nodes
        yaml_data.each do |item|
          node = Node.new(item["id"], item["name"], item["attributes"])
          nodes[item["id"]] = node
          parent&.add_child(node)
        end

        # Second pass: Build relationships
        yaml_data.each do |item|
          parent = nodes[item["id"]]
          item["children"]&.each do |child_id|
            child = nodes[child_id]
            parent.add_child(child) if child
          end
        end

        # Return the first node if no parent was provided
        parent ? parent : nodes[yaml_data.first["id"]]
      end

      def print_tree(node, level = 0)
        puts "#{" " * level}#{node.id}: #{node.name}"
        node.children.each { |child| print_tree(child, level + 2) }
      end
    end
  end
end
