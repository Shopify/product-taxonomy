#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

file = "data/integrations/google/2024-05-01/categories/nodes.yml"
output_file = "data/integrations/google/2024-05-01/categories/new_nodes.yml"
data = YAML.load_file(file)

id_mapping = {}

data.each do |item|
  id_mapping[item["id"]] = item["public_id"]
end

modified_content = data.map do |item|
  item["id"] = id_mapping[item["id"]]
  item["children_ids"] = item["children_ids"].map { |id| id_mapping[id] } if item["children_ids"]
  item["ancestor_ids"] = item["ancestor_ids"].map { |id| id_mapping[id] } if item["ancestor_ids"]
  ["public_id", "archived", "taxonomy_id", "parent_id", "fully_qualified_type", "migrated_to_node_id"].each do |key|
    item.delete(key)
  end
  item
end

File.open(output_file, "w") { |f| f.write(modified_content.to_yaml) }
