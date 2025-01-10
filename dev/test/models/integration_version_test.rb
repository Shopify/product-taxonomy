# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class IntegrationVersionTest < TestCase
    DATA_PATH = File.expand_path("../fixtures/data", __dir__)

    setup do
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
      @current_shopify_version = "2025-01-unstable"
      @shopify_integration = IntegrationVersion.load_from_source(
        integration_path: File.expand_path("integrations/shopify/2020-01", DATA_PATH),
        current_shopify_version: @current_shopify_version,
      )
      @shopify_integration.resolve_to_shopify_mappings([]) # Resolve against current version
      @external_integration = IntegrationVersion.load_from_source(
        integration_path: File.expand_path("integrations/foocommerce/1.0.0", DATA_PATH),
        current_shopify_version: @current_shopify_version,
      )
    end

    test "IntegrationVersion.load_from_source loads the integration version with the correct version and name" do
      assert_equal "2020-01", @shopify_integration.version
      assert_equal "shopify", @shopify_integration.name
    end

    test "IntegrationVersion.load_all_from_source loads all integration versions" do
      integrations_path = File.expand_path("integrations", DATA_PATH)
      integration_versions = IntegrationVersion.load_all_from_source(
        base_path: integrations_path,
        current_shopify_version: @current_shopify_version,
      )

      assert_equal 4, integration_versions.size
      assert_equal "foocommerce", integration_versions.first.name
      assert_equal "1.0.0", integration_versions.first.version
      assert_equal "shopify", integration_versions.second.name
      assert_equal "2020-01", integration_versions.second.version
      assert_equal "shopify", integration_versions.third.name
      assert_equal "2021-01", integration_versions.third.version
      assert_equal "shopify", integration_versions.fourth.name
      assert_equal "2022-01", integration_versions.fourth.version
    end

    test "IntegrationVersion.load_all_from_source resolves chain of to_shopify mappings against latest version" do
      integrations_path = File.expand_path("integrations", DATA_PATH)
      integration_versions = IntegrationVersion.load_all_from_source(
        base_path: integrations_path,
        current_shopify_version: @current_shopify_version,
      )
      output_mappings = integration_versions
        .index_by { "#{_1.name}/#{_1.version}" }
        .transform_values(&:to_shopify_mappings)

      # 2022: mapped to aa-3, latest
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", output_mappings["shopify/2022-01"].first.output_category.gid
      # 2021: mapped to aa-2, continues to resolve to aa-3
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", output_mappings["shopify/2021-01"].first.output_category.gid
      # 2020: mapped to aa-1, continues to resolve to aa-3
      assert_equal "gid://shopify/TaxonomyCategory/aa", output_mappings["shopify/2020-01"].first.output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", output_mappings["shopify/2020-01"].second.output_category.gid
    end

    test "to_json returns the JSON representation of a mapping to Shopify" do
      expected_json = {
        input_taxonomy: "shopify/2020-01",
        output_taxonomy: "shopify/2025-01-unstable",
        rules: [
          {
            input: { category: { id: "1", full_name: "Apparel & Accessories (2020-01)" } },
            output: {
              category: [{
                id: "gid://shopify/TaxonomyCategory/aa",
                full_name: "Apparel & Accessories",
              }],
            },
          },
          {
            input: { category: { id: "2", full_name: "Apparel & Accessories > Clothing (2020-01)" } },
            output: {
              category: [{
                id: "gid://shopify/TaxonomyCategory/aa-1",
                full_name: "Apparel & Accessories > Clothing",
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
            input: { category: { id: "gid://shopify/TaxonomyCategory/aa", full_name: "Apparel & Accessories" } },
            output: {
              category: [{
                id: "1",
                full_name: "Apparel & Accessories (foocommerce)",
              }],
            },
          },
          {
            input: {
              category: {
                id: "gid://shopify/TaxonomyCategory/aa-1",
                full_name: "Apparel & Accessories > Clothing",
              },
            },
            output: { category: [{ id: "2", full_name: "Apparel & Accessories > Clothing (foocommerce)" }] },
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

        → Apparel & Accessories (2020-01)
        ⇒ Apparel & Accessories

        → Apparel & Accessories > Clothing (2020-01)
        ⇒ Apparel & Accessories > Clothing
      TXT
      assert_equal expected_txt.chomp, @shopify_integration.to_txt(direction: :to_shopify)
    end

    test "to_txt returns the TXT representation of a mapping from Shopify" do
      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Mapping shopify/2025-01-unstable to foocommerce/1.0.0
        # Format:
        # → {base taxonomy category name}
        # ⇒ {mapped taxonomy category name}

        → Apparel & Accessories
        ⇒ Apparel & Accessories (foocommerce)

        → Apparel & Accessories > Clothing
        ⇒ Apparel & Accessories > Clothing (foocommerce)
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
        JSON.pretty_generate(expected_shopify_json) + "\n",
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/shopify/shopify_2020-01_to_shopify_2025-01.txt",
        @shopify_integration.to_txt(direction: :to_shopify) + "\n",
      )

      assert_nothing_raised do
        @shopify_integration.generate_distribution(
          output_path: "/tmp/fake",
          direction: :to_shopify,
        )
      end
    end

    test "generate_distribution generates the distribution files for a mapping from Shopify" do
      FileUtils.expects(:mkdir_p).with("/tmp/fake/en/integrations/foocommerce")
      expected_external_json = {
        version: "2025-01-unstable",
        mappings: [@external_integration.to_json(direction: :from_shopify)],
      }
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.json",
        JSON.pretty_generate(expected_external_json) + "\n",
      )
      File.expects(:write).with(
        "/tmp/fake/en/integrations/foocommerce/shopify_2025-01_to_foocommerce_1.0.0.txt",
        @external_integration.to_txt(direction: :from_shopify) + "\n",
      )

      assert_nothing_raised do
        @external_integration.generate_distribution(
          output_path: "/tmp/fake",
          direction: :from_shopify,
        )
      end
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

    test "unmapped_external_category_ids returns IDs of external categories not mapped from the Shopify taxonomy" do
      external_category1 = category_hash("1")
      from_shopify_mappings = [
        MappingRule.new(
          input_category: Category.new(id: "aa", name: "aa"),
          output_category: external_category1,
        ),
      ]
      full_names_by_id = {
        "1" => external_category1,
        "2" => { "id" => "2", "full_name" => "External category 2" },
        "3" => { "id" => "3", "full_name" => "External category 3" },
      }
      integration_version = IntegrationVersion.new(
        name: "test",
        version: "1.0.0",
        from_shopify_mappings:,
        full_names_by_id:,
      )

      assert_equal ["2", "3"], integration_version.unmapped_external_category_ids
    end

    test "resolve_to_shopify_mappings resolves mappings to the latest version of the Shopify taxonomy" do
      mapping = MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2")
      integration_version = IntegrationVersion.new(
        name: "shopify",
        version: "2020-01",
        to_shopify_mappings: [mapping],
        full_names_by_id: {},
      )
      integration_version.resolve_to_shopify_mappings([])
      assert_equal "gid://shopify/TaxonomyCategory/aa-2", mapping.output_category.gid
    end

    test "resolve_to_shopify_mappings raises an error if a mapping cannot be resolved" do
      mapping = MappingRule.new(input_category: category_hash("aa-1"), output_category: "invalid")
      integration_version = IntegrationVersion.new(
        name: "shopify",
        version: "2020-01",
        to_shopify_mappings: [mapping],
        full_names_by_id: {},
      )
      assert_raises(ArgumentError) { integration_version.resolve_to_shopify_mappings([]) }
    end

    test "IntegrationVersion.resolve_to_shopify_mappings_chain resolves mappings to the current version of the Shopify taxonomy" do
      version = IntegrationVersion.new(
        name: "shopify",
        version: "2020-01",
        to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2")],
        full_names_by_id: {},
      )
      IntegrationVersion.resolve_to_shopify_mappings_chain([version])
      assert_equal "gid://shopify/TaxonomyCategory/aa-2", version.to_shopify_mappings[0].output_category.gid
    end

    test "IntegrationVersion.resolve_to_shopify_mappings_chain resolves mappings through two versions without chained mappings" do
      versions = [
        IntegrationVersion.new(
          name: "shopify",
          version: "2020-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2021-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("bb-1"), output_category: "aa-1")],
          full_names_by_id: {},
        ),
      ]
      IntegrationVersion.resolve_to_shopify_mappings_chain(versions)
      assert_equal "gid://shopify/TaxonomyCategory/aa-2", versions[0].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-1", versions[1].to_shopify_mappings[0].output_category.gid
    end

    test "IntegrationVersion.resolve_to_shopify_mappings_chain resolves mappings through two versions with chained mappings" do
      versions = [
        IntegrationVersion.new(
          name: "shopify",
          version: "2020-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2021-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-2"), output_category: "aa-3")],
          full_names_by_id: {},
        ),
      ]
      IntegrationVersion.resolve_to_shopify_mappings_chain(versions)
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[0].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[1].to_shopify_mappings[0].output_category.gid
    end

    test "IntegrationVersion.resolve_to_shopify_mappings_chain resolves mappings through four versions with non-consecutive chained mappings" do
      versions = [
        IntegrationVersion.new(
          name: "shopify",
          version: "2020-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2021-01",
          to_shopify_mappings: [],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2022-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-2"), output_category: "aa-3")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2023-01",
          to_shopify_mappings: [],
          full_names_by_id: {},
        ),
      ]
      IntegrationVersion.resolve_to_shopify_mappings_chain(versions)
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[0].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[2].to_shopify_mappings[0].output_category.gid
    end

    test "IntegrationVersion.resolve_to_shopify_mappings_chain resolves mappings through four versions with a mix of chained and non-chained mappings" do
      versions = [
        IntegrationVersion.new(
          name: "shopify",
          version: "2020-01",
          to_shopify_mappings: [
            MappingRule.new(input_category: category_hash("aa-1"), output_category: "aa-2"),
            MappingRule.new(input_category: category_hash("bb-1"), output_category: "aa-1"),
          ],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2021-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("cc-1"), output_category: "aa-1")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2022-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("aa-2"), output_category: "aa-3")],
          full_names_by_id: {},
        ),
        IntegrationVersion.new(
          name: "shopify",
          version: "2023-01",
          to_shopify_mappings: [MappingRule.new(input_category: category_hash("dd-1"), output_category: "aa-2")],
          full_names_by_id: {},
        ),
      ]
      IntegrationVersion.resolve_to_shopify_mappings_chain(versions)
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[0].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-1", versions[0].to_shopify_mappings[1].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-1", versions[1].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-3", versions[2].to_shopify_mappings[0].output_category.gid
      assert_equal "gid://shopify/TaxonomyCategory/aa-2", versions[3].to_shopify_mappings[0].output_category.gid
    end

    def category_hash(id)
      { "id" => id, "full_name" => "Category #{id}" }
    end
  end
end
