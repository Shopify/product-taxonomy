#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
nodes_file = File.expand_path("2024-05-01/categories/nodes.yml", File.dirname(__FILE__))
mapped_nodes_file = File.expand_path("../../../docs/_data/unstable/mappings.yml", File.dirname(__FILE__))
output_file = File.expand_path("2024-05-01/categories/mapped_nodes.yml", File.dirname(__FILE__))
output_file_docs = File.expand_path("../../../docs/_data/unstable/mapped_nodes.yml", File.dirname(__FILE__))
data = YAML.load_file(nodes_file)

mapped_nodes = {}
mappings = YAML.load_file(mapped_nodes_file).map do |mapping|
  if mapping["output_taxonomy"].include?("google")
    mapping["rules"].map do |rule|
      mapped_nodes[rule['output']['product_category_id']] = rule['input']['product_category_id']
    end
  end
end

id_mapping = {}
data.each do |item|
  id_mapping[item["id"]] = item["public_id"].gsub("google-", "")
end

modified_content = data.map do |item|
  item["id"] = id_mapping[item["id"]]
  item["children_ids"] = item["children_ids"].map { |id| id_mapping[id] } if item["children_ids"]
  item["ancestor_ids"] = item["ancestor_ids"].map { |id| id_mapping[id] } if item["ancestor_ids"]
  item["shopify_id"] = mapped_nodes[item["id"]]
  ["public_id", "archived", "taxonomy_id", "parent_id", "fully_qualified_type", "migrated_to_node_id"].each do |key|
    item.delete(key)
  end
  item
end

File.open(output_file, "w") { |f| f.write(modified_content.to_yaml) }
File.open(output_file_docs, "w") { |f| f.write(modified_content.to_yaml) }
