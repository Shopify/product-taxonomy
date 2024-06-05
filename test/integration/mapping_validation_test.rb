# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../config/cli"

class LocalizationsTest < ActiveSupport::TestCase
  test "category IDs in mappings are valid" do
    mappings_json_data = CLI.new.parse_json("dist/en/integrations/all_mappings.json")
    invalid_categories = []
    mappings_json_data["mappings"].each do |mapping|
      # process input taxonomy
      category_ids = get_category_ids(mapping["input_taxonomy"])
      res = validate_mapping_category_ids(mapping["rules"], category_ids, "input", mapping["input_taxonomy"])
      unless res[:all_mapping_category_ids_are_valid]
        invalid_categories.push(res[:invalid_categories])
      end

      # process output taxonomy
      category_ids = get_category_ids(mapping["output_taxonomy"])
      res = validate_mapping_category_ids(mapping["rules"], category_ids, "output", mapping["output_taxonomy"])
      unless res[:all_mapping_category_ids_are_valid]
        invalid_categories.push(res[:invalid_categories])
      end
    end

    assert invalid_categories.empty?,
      "The following category ids in mappings are invalid:
    #{invalid_categories}"
  end

  def validate_mapping_category_ids(mapping_rules, category_ids, input_or_output, input_or_output_taxonomy)
    if category_ids.nil?
      return {
        all_mapping_category_ids_are_valid: true,
      }
    end

    invalid_category_ids_in_input_taxonomy = Set.new
    invalid_category_ids_in_output_taxonomy = Set.new

    if input_or_output == "input"
      mapping_rules.each do |rule|
        product_category_id = rule[input_or_output]["category"]["id"]
        unless category_ids.include?(product_category_id)
          invalid_category_ids_in_input_taxonomy.add(product_category_id)
        end
      end
    else
      mapping_rules.each do |rule|
        product_categories = rule[input_or_output]["category"]
        product_categories.each do |product_category|
          unless category_ids.include?(product_category["id"])
            invalid_category_ids_in_output_taxonomy.add(product_category["id"])
          end
        end
      end
    end
    invalid_categories = []

    unless invalid_category_ids_in_input_taxonomy.empty?
      invalid_categories.push({
        taxonomy_version: input_or_output_taxonomy,
        category_ids: invalid_category_ids_in_input_taxonomy,
      })
    end

    unless invalid_category_ids_in_output_taxonomy.empty?
      invalid_categories.push({
        taxonomy_version: input_or_output_taxonomy,
        category_ids: invalid_category_ids_in_output_taxonomy,
      })
    end

    if invalid_category_ids_in_input_taxonomy.empty? &&
        invalid_category_ids_in_output_taxonomy.empty?
      {
        all_mapping_category_ids_are_valid: true,
      }
    else
      {
        all_mapping_category_ids_are_valid: false,
        invalid_categories: invalid_categories,
      }
    end
  end

  def get_category_ids(input_or_output_taxonomy)
    cli = CLI.new
    if input_or_output_taxonomy.include?("shopify/2022-02")
      nil
    elsif input_or_output_taxonomy.include?("shopify")
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
