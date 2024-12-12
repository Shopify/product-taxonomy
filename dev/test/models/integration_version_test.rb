# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class IntegrationVersionTest < TestCase
    DATA_PATH = File.expand_path("../fixtures/data", __dir__)

    setup do
      ap = Category.new(id: "ap", name: "Animals & Pet Supplies")
      ap_1 = Category.new(id: "ap-1", name: "Live Animals")
      ap.add_child(ap_1)
      Category.add(ap)
      Category.add(ap_1)
      @current_shopify_version = "2025-01-unstable"
      @shopify_integration = IntegrationVersion.load_from_source(
        integration_path: File.expand_path("integrations/shopify/2020-01", DATA_PATH),
        current_shopify_version: @current_shopify_version,
      )
      @external_integration = IntegrationVersion.load_from_source(
        integration_path: File.expand_path("integrations/foocommerce/1.0.0", DATA_PATH),
        current_shopify_version: @current_shopify_version,
      )
    end

    test "load_from_source loads the integration version with the correct version and name" do
      assert_equal "2020-01", @shopify_integration.version
      assert_equal "shopify", @shopify_integration.name
    end

    test "load_all_from_source loads all integration versions" do
      integrations_path = File.expand_path("integrations", DATA_PATH)
      integration_versions = IntegrationVersion.load_all_from_source(
        base_path: integrations_path,
        current_shopify_version: @current_shopify_version,
      )

      assert_equal 2, integration_versions.size
      assert_equal "foocommerce", integration_versions.first.name
      assert_equal "1.0.0", integration_versions.first.version
      assert_equal "shopify", integration_versions.last.name
      assert_equal "2020-01", integration_versions.last.version
    end

    test "to_json returns the JSON representation of a mapping to Shopify" do
      expected_json = {
        input_taxonomy: "shopify/2020-01",
        output_taxonomy: "shopify/2025-01-unstable",
        rules: [
          {
            input: { category: { id: "1", full_name: "Animals & Pet Supplies (old shopify)" } },
            output: {
              category: [{
                id: "gid://shopify/TaxonomyCategory/ap",
                full_name: "Animals & Pet Supplies",
              }],
            },
          },
          {
            input: {
              category: {
                id: "2",
                full_name: "Animals & Pet Supplies > Live Animals (old shopify)",
              },
            },
            output: {
              category: [{
                id: "gid://shopify/TaxonomyCategory/ap-1",
                full_name: "Animals & Pet Supplies > Live Animals",
              }],
            },
          },
        ],
      }
      assert_equal expected_json, @shopify_integration.to_json(direction: :to_shopify)
    end

    test "to_json returns the JSON representation of a mapping from Shopify" do
      expected_json = {
        input_taxonomy: "shopify/2025-01-unstable",
        output_taxonomy: "foocommerce/1.0.0",
        rules: [
          {
            input: { category: { id: "gid://shopify/TaxonomyCategory/ap", full_name: "Animals & Pet Supplies" } },
            output: {
              category: [{
                id: "1",
                full_name: "Animals & Pet Supplies (foocommerce)",
              }],
            },
          },
          {
            input: {
              category: {
                id: "gid://shopify/TaxonomyCategory/ap-1",
                full_name: "Animals & Pet Supplies > Live Animals",
              },
            },
            output: {
              category: [{
                id: "2",
                full_name: "Animals & Pet Supplies > Live Animals (foocommerce)",
              }],
            },
          },
        ],
      }
      assert_equal expected_json, @external_integration.to_json(direction: :from_shopify)
    end

    test "to_txt returns the TXT representation of a mapping to Shopify" do
      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Mapping shopify/2020-01 to shopify/2025-01-unstable
        # Format:
        # → {base taxonomy category name}
        # ⇒ {mapped taxonomy category name}

        → Animals & Pet Supplies (old shopify)
        ⇒ Animals & Pet Supplies

        → Animals & Pet Supplies > Live Animals (old shopify)
        ⇒ Animals & Pet Supplies > Live Animals
      TXT
      assert_equal expected_txt.chomp, @shopify_integration.to_txt(direction: :to_shopify)
    end

    test "to_txt returns the TXT representation of a mapping from Shopify" do
      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Mapping shopify/2025-01-unstable to foocommerce/1.0.0
        # Format:
        # → {base taxonomy category name}
        # ⇒ {mapped taxonomy category name}

        → Animals & Pet Supplies
        ⇒ Animals & Pet Supplies (foocommerce)

        → Animals & Pet Supplies > Live Animals
        ⇒ Animals & Pet Supplies > Live Animals (foocommerce)
      TXT
      assert_equal expected_txt.chomp, @external_integration.to_txt(direction: :from_shopify)
    end

    test "generate_distribution generates the distribution files for a mapping to Shopify" do
      FileUtils.expects(:mkdir_p).with("/tmp/fake/en/integrations/shopify")
      expected_shopify_json = {
        version: "2025-01-unstable",
        mappings: [@shopify_integration.to_json(direction: :to_shopify)],
      }
      File.expects(:write).with(
        "/tmp/fake/en/integrations/shopify/shopify_2020-01_to_shopify_2025-01.json",
        JSON.pretty_generate(expected_shopify_json),
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/shopify/shopify_2020-01_to_shopify_2025-01.txt",
        @shopify_integration.to_txt(direction: :to_shopify),
      )
      @shopify_integration.generate_distribution(
        output_path: "/tmp/fake",
        direction: :to_shopify,
      )
    end

    test "generate_distribution generates the distribution files for a mapping from Shopify" do
      FileUtils.expects(:mkdir_p).with("/tmp/fake/en/integrations/foocommerce")
      expected_external_json = {
        version: "2025-01-unstable",
        mappings: [@external_integration.to_json(direction: :from_shopify)],
      }
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.json",
        JSON.pretty_generate(expected_external_json),
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.txt",
        @external_integration.to_txt(direction: :from_shopify),
      )
      @external_integration.generate_distribution(
        output_path: "/tmp/fake",
        direction: :from_shopify,
      )
    end

    test "generate_distributions only calls generate_distribution with to_shopify for Shopify integration version" do
      @shopify_integration.expects(:generate_distribution).with(output_path: "/tmp/fake", direction: :to_shopify)
      @shopify_integration.generate_distributions(output_path: "/tmp/fake")
    end

    test "generate_distributions only calls generate_distribution with from_shopify for external integration version" do
      @external_integration.expects(:generate_distribution).with(output_path: "/tmp/fake", direction: :from_shopify)
      @external_integration.generate_distributions(output_path: "/tmp/fake")
    end

    test "IntegrationVersion.to_json returns the JSON representation of a list of mappings" do
      mappings = [
        {
          input_taxonomy: "shopify/2020-01",
          output_taxonomy: "shopify/2025-01-unstable",
          rules: [
            {
              input: { category: { id: "1", full_name: "Animals & Pet Supplies (old shopify)" } },
            },
          ],
        },
      ]
      expected_json = {
        version: "2025-01-unstable",
        mappings:,
      }
      assert_equal expected_json, IntegrationVersion.to_json(mappings:, current_shopify_version: "2025-01-unstable")
    end

    test "generate_all_distributions generates all_mappings.json and distribution files for all integration versions" do
      FileUtils.expects(:mkdir_p).with("/tmp/fake/en/integrations/foocommerce")
      FileUtils.expects(:mkdir_p).with("/tmp/fake/en/integrations/shopify")
      expected_external_json = IntegrationVersion.to_json(
        mappings: [@external_integration.to_json(direction: :from_shopify)],
        current_shopify_version: @current_shopify_version,
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.json",
        JSON.pretty_generate(expected_external_json),
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.txt",
        @external_integration.to_txt(direction: :from_shopify),
      )
      expected_shopify_json = IntegrationVersion.to_json(
        mappings: [@shopify_integration.to_json(direction: :to_shopify)],
        current_shopify_version: @current_shopify_version,
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/shopify/shopify_2020-01_to_shopify_2025-01.json",
        JSON.pretty_generate(expected_shopify_json),
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/shopify/shopify_2020-01_to_shopify_2025-01.txt",
        @shopify_integration.to_txt(direction: :to_shopify),
      )
      all_mappings_json = IntegrationVersion.to_json(
        mappings: [
          @external_integration.to_json(direction: :from_shopify),
          @shopify_integration.to_json(direction: :to_shopify),
        ],
        current_shopify_version: @current_shopify_version,
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/all_mappings.json",
        JSON.pretty_generate(all_mappings_json),
      )
      IntegrationVersion.generate_all_distributions(
        output_path: "/tmp/fake",
        current_shopify_version: @current_shopify_version,
        logger: stub("logger", info: nil),
        base_path: File.expand_path("integrations", DATA_PATH),
      )
    end
  end
end
