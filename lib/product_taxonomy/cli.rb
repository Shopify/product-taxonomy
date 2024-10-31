# frozen_string_literal: true

require "yaml"
require "benchmark"

require_relative "models/node"

module ProductTaxonomy
  class CLI
    class << self
      def start(args)
        yaml_files = Dir.glob("data/categories/*.yml")

        Benchmark.bm(7) do |x|
          yaml_content = nil
          root = Node.new("root", "Root")

          x.report("Total") do
            yaml_files.each do |yaml_file|
              yaml_content = File.read(yaml_file)
              file_data = YAML.safe_load(yaml_content)
              build_tree(file_data, root)
            end
            print_tree(root)
          end
        end
      end

      def build_tree(yaml_data, parent = nil)
        nodes = {}

        # First pass: Create all nodes
        yaml_data.each do |item|
          node = Node.new(item["id"], item["name"], item["attributes"])
          nodes[item["id"]] = node
          parent.add_child(node) if parent
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
