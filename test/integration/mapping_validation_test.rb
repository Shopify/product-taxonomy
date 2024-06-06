# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../config/cli"

class MappingValidationTest < ActiveSupport::TestCase
  test "category IDs in mappings are valid" do
    mappings_json_data = CLI.new.parse_json("dist/en/integrations/all_mappings.json")
    invalid_categories = []
    mappings_json_data["mappings"].each do |mapping|
      res = validate_mapping_category_ids(mapping["rules"], "input", mapping["input_taxonomy"])
      invalid_categories.concat(res)

      res = validate_mapping_category_ids(mapping["rules"], "output", mapping["output_taxonomy"])
      invalid_categories.concat(res)
    end

    assert invalid_categories.empty?,
      "The following category ids in mappings are invalid:
      #{invalid_categories}"
  end

  def validate_mapping_category_ids(mapping_rules, input_or_output, input_or_output_taxonomy)
    category_ids = category_ids_from_taxonomy(input_or_output_taxonomy)

    return [] if category_ids.nil?

    invalid_category_ids = Set.new

    mapping_rules.each do |rule|
      product_categories = rule[input_or_output]["category"]
      product_categories = [product_categories] unless product_categories.is_a?(Array)

      product_categories.each do |product_category|
        invalid_category_ids.add(product_category["id"]) unless category_ids.include?(product_category["id"])
      end
    end

    if invalid_category_ids.empty?
      []
    else
      [
        {
          taxonomy_version: input_or_output_taxonomy,
          input_or_output: input_or_output,
          category_ids: invalid_category_ids,
        },
      ]
    end
  end

  def category_ids_from_taxonomy(input_or_output_taxonomy)
    return if input_or_output_taxonomy.include?("shopify/2022-02")

    cli = CLI.new

    if input_or_output_taxonomy.include?("shopify")
      categories_json_data = cli.parse_json("dist/en/categories.json")
      shopify_category_ids = Set.new
      categories_json_data["verticals"].each do |vertical|
        vertical["categories"].each do |category|
          shopify_category_ids.add(category["id"])
        end
      end
      shopify_category_ids
    else
      channel_category_ids = Set.new
      file_path = "data/integrations/#{input_or_output_taxonomy}/full_names.yml"
      channel_taxonomy = cli.parse_yaml(file_path)
      channel_taxonomy.each do |entry|
        channel_category_ids.add(entry["id"].to_s)
      end
      channel_category_ids
    end
  end
end
