# frozen_string_literal: true

require_relative "../test_helper"

class MappingValidationTest < ActiveSupport::TestCase
  def setup
    @sys = System.new
    @mappings_json_data = @sys.parse_json("dist/en/integrations/all_mappings.json")
  end

  test "category IDs in mappings are valid" do
    invalid_categories = []
    @mappings_json_data["mappings"].each do |mapping|
      res = validate_mapping_category_ids(mapping["rules"], "input", mapping["input_taxonomy"])
      invalid_categories.concat(res)

      res = validate_mapping_category_ids(mapping["rules"], "output", mapping["output_taxonomy"])
      invalid_categories.concat(res)
    end

    assert invalid_categories.empty?,
      "The following category ids in mappings are invalid:
      #{invalid_categories}"
  end

  test "every Shopify category has corresponding channel mappings" do
    shopify_categories_lack_mappings = []
    @mappings_json_data["mappings"].each do |mapping|
      next unless mapping["input_taxonomy"].include?("shopify")

      all_shopify_category_ids = category_ids_from_taxonomy(mapping["input_taxonomy"])
      next if all_shopify_category_ids.nil?

      excluded_category_ids = excluded_category_ids(
        mapping["input_taxonomy"],
        mapping["input_taxonomy"],
        mapping["output_taxonomy"],
      )

      excluded_category_ids = if !excluded_category_ids.nil? &&
          all_shopify_category_ids.first.include?("gid://shopify/TaxonomyCategory/")
        excluded_category_ids.map { |id| "gid://shopify/TaxonomyCategory/#{id}" }.to_set
      end

      shopify_category_ids_from_mappings_input = mapping["rules"]
        .map { _1.dig("input", "category", "id") }
        .to_set

      unmapped_category_ids = if excluded_category_ids.nil?
        all_shopify_category_ids - shopify_category_ids_from_mappings_input
      else
        all_shopify_category_ids - shopify_category_ids_from_mappings_input - excluded_category_ids
      end

      next if unmapped_category_ids.empty?

      shopify_categories_lack_mappings << {
        input_taxonomy: mapping["input_taxonomy"],
        output_taxonomy: mapping["output_taxonomy"],
        unmapped_category_ids: unmapped_category_ids,
      }
    end

    unless shopify_categories_lack_mappings.empty?
      puts "Shopify Categories are missing mappings for the following integrations:"
      shopify_categories_lack_mappings.each_with_index do |mapping, index|
        puts ""
        puts "[#{index + 1}] #{mapping[:input_taxonomy]} to #{mapping[:output_taxonomy]} (#{mapping[:unmapped_category_ids].size} missing)"
        mapping[:unmapped_category_ids].each do |category_id|
          puts " - #{category_id}"
        end
      end
      assert(shopify_categories_lack_mappings.empty?, "Shopify Categories are missing mappings.")
    end
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
    if input_or_output_taxonomy.include?("shopify") && !input_or_output_taxonomy.include?("shopify/2022-02")
      categories_json_data = @sys.parse_json("dist/en/categories.json")
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
      channel_taxonomy = @sys.parse_yaml(file_path)
      channel_taxonomy.each do |entry|
        channel_category_ids.add(entry["id"].to_s)
      end
      channel_category_ids
    end
  end

  def excluded_category_ids(excluded_taxonomy_version, mappings_input_taxonomy, mappings_output_taxonomy)
    integration_version_path = if mappings_input_taxonomy.include?("shopify") &&
        mappings_output_taxonomy.include?("shopify")
      "shopify/2022-02"
    elsif mappings_input_taxonomy.include?("shopify")
      mappings_output_taxonomy
    else
      mappings_input_taxonomy
    end

    file_path = "data/integrations/#{integration_version_path}/excluded_taxonomy_for_mappings.yml"
    return unless File.exist?(file_path)

    excluded_taxonomy_for_mappings = CLI.new.parse_yaml(file_path)

    excluded_category_ids = nil
    excluded_taxonomy_for_mappings.each do |entry|
      if entry["input_taxonomy"] == excluded_taxonomy_version
        excluded_category_ids = entry["product_category_ids"]
        break
      end
    end
    excluded_category_ids
  end
end
