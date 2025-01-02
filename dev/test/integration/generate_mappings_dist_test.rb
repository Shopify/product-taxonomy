# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

module ProductTaxonomy
  class GenerateMappingsDistTest < TestCase
    FIXTURES_PATH = File.expand_path("../fixtures", __dir__)

    setup do
      @tmp_path = Dir.mktmpdir
      @current_shopify_version = "2025-01-unstable"

      # Create categories so they can be resolved
      aa = Category.new(id: "aa", name: "Apparel & Accessories")
      aa_1 = Category.new(id: "aa-1", name: "Clothing")
      aa_2 = Category.new(id: "aa-2", name: "Clothing Accessories")
      aa_3 = Category.new(id: "aa-3", name: "Costumes & Accessories")
      aa.add_child(aa_1)
      aa.add_child(aa_2)
      aa.add_child(aa_3)
      Category.add(aa)
      Category.add(aa_1)
      Category.add(aa_2)
      Category.add(aa_3)
    end

    teardown do
      FileUtils.remove_entry(@tmp_path)
    end

    test "IntegrationVersion.generate_all_distributions generates all_mappings.json and distribution files for all integration versions" do
      IntegrationVersion.generate_all_distributions(
        output_path: @tmp_path,
        current_shopify_version: @current_shopify_version,
        logger: stub("logger", info: nil),
        base_path: File.expand_path("data/integrations", FIXTURES_PATH),
      )

      assert_file_matches_fixture "all_mappings.json"
      assert_file_matches_fixture "shopify/shopify_2020-01_to_shopify_2025-01.json"
      assert_file_matches_fixture "shopify/shopify_2020-01_to_shopify_2025-01.txt"
      assert_file_matches_fixture "shopify/shopify_2021-01_to_shopify_2025-01.json"
      assert_file_matches_fixture "shopify/shopify_2021-01_to_shopify_2025-01.txt"
      assert_file_matches_fixture "shopify/shopify_2022-01_to_shopify_2025-01.json"
      assert_file_matches_fixture "shopify/shopify_2022-01_to_shopify_2025-01.txt"
      assert_file_matches_fixture "foocommerce/shopify_2025-01_to_foocommerce_1.0.0.json"
      assert_file_matches_fixture "foocommerce/shopify_2025-01_to_foocommerce_1.0.0.txt"
    end

    def assert_file_matches_fixture(file_path)
      fixture_path = File.expand_path("dist/en/integrations/#{file_path}", FIXTURES_PATH)
      expected_path = File.expand_path("en/integrations/#{file_path}", @tmp_path)

      assert(File.exist?(expected_path), "Expected file to exist: #{expected_path}")
      assert_equal(File.read(fixture_path), File.read(expected_path), "File contents don't match for: #{file_path}")
    end
  end
end
