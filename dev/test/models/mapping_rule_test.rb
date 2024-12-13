# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class MappingRuleTest < TestCase
    setup do
      @shopify_category = Category.new(id: "aa", name: "Shopify category")
      @integration_category = {
        "id" => "166",
        "full_name" => "Integration category",
      }
      Category.add(@shopify_category)
    end

    test "load_rules_from_source loads rules from source for from_shopify direction without errors" do
      full_names_by_id = {
        "166" => { "id" => "166", "full_name" => "Integration category" },
      }
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/from_shopify.yml").returns(true)
      YAML.expects(:safe_load_file).with("/fake/data/integrations/google/2021-09-21/mappings/from_shopify.yml").returns(
        "rules" => [
          { "input" => { "product_category_id" => "aa" }, "output" => { "product_category_id" => ["166"] } },
        ],
      )
      rules = MappingRule.load_rules_from_source(
        integration_path: "/fake/data/integrations/google/2021-09-21",
        direction: :from_shopify,
        full_names_by_id:,
      )

      assert_equal 1, rules.size
    end

    test "load_rules_from_source loads rules from source for to_shopify direction without errors" do
      full_names_by_id = {
        "166" => { "id" => "166", "full_name" => "Integration category" },
      }
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(
        "rules" => [
          { "input" => { "product_category_id" => "166" }, "output" => { "product_category_id" => ["aa"] } },
        ],
      )
      rules = MappingRule.load_rules_from_source(
        integration_path: "/fake/data/integrations/google/2021-09-21",
        direction: :to_shopify,
        full_names_by_id:,
      )

      assert_equal 1, rules.size
    end

    test "load_rules_from_source returns nil if the file does not exist" do
      full_names_by_id = {
        "166" => { "id" => "166", "full_name" => "Integration category" },
      }
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/from_shopify.yml").returns(false)
      rules = MappingRule.load_rules_from_source(
        integration_path: "/fake/data/integrations/google/2021-09-21",
        direction: :from_shopify,
        full_names_by_id:,
      )

      assert_nil rules
    end

    test "load_rules_from_source raises an error if the file does not contain a hash" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("foo")

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the file does not contain a rules key" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns({ foo: "bar" })

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the input category is not found" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "input" => { "product_category_id" => "166" }, "output" => { "product_category_id" => ["aa"] } },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the output category is not found" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "input" => { "product_category_id" => "166" }, "output" => { "product_category_id" => ["bb"] } },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: { "166" => { "id" => "166", "full_name" => "Integration category" } },
        )
      end
    end

    test "load_rules_from_source raises an error if the mapping definition is invalid" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "foo" => "bar" },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the mapping input is not a hash" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "input" => "foo", "output" => { "product_category_id" => ["aa"] } },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the mapping input hash key is invalid" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "input" => { "id" => "foo" }, "output" => { "product_category_id" => ["aa"] } },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "load_rules_from_source raises an error if the mapping output ID value is not an array" do
      File.expects(:exist?).with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml").returns(true)
      YAML.expects(:safe_load_file)
        .with("/fake/data/integrations/google/2021-09-21/mappings/to_shopify.yml")
        .returns("rules" => [
          { "input" => { "product_category_id" => "166" }, "output" => { "product_category_id" => 1 } },
        ])

      assert_raises(ArgumentError) do
        MappingRule.load_rules_from_source(
          integration_path: "/fake/data/integrations/google/2021-09-21",
          direction: :to_shopify,
          full_names_by_id: {},
        )
      end
    end

    test "to_json returns correct JSON with Shopify input and integration output" do
      rule = MappingRule.new(
        input_category: @shopify_category,
        output_category: @integration_category,
      )

      expected_json = {
        input: { category: { id: "gid://shopify/TaxonomyCategory/aa", full_name: "Shopify category" } },
        output: { category: [{ id: "166", full_name: "Integration category" }] },
      }
      assert_equal expected_json, rule.to_json.deep_symbolize_keys
    end

    test "to_json returns correct JSON with integration input and Shopify output" do
      rule = MappingRule.new(
        input_category: @integration_category,
        output_category: @shopify_category,
      )

      expected_json = {
        input: { category: { id: "166", full_name: "Integration category" } },
        output: { category: [{ id: "gid://shopify/TaxonomyCategory/aa", full_name: "Shopify category" }] },
      }
      assert_equal expected_json, rule.to_json.deep_symbolize_keys
    end

    test "to_txt returns correct TXT with Shopify input and integration output" do
      rule = MappingRule.new(
        input_category: @shopify_category,
        output_category: @integration_category,
      )

      expected_txt = <<~TXT
        → Shopify category
        ⇒ Integration category
      TXT
      assert_equal expected_txt, rule.to_txt
    end

    test "to_txt returns correct TXT with integration input and Shopify output" do
      rule = MappingRule.new(
        input_category: @integration_category,
        output_category: @shopify_category,
      )

      expected_txt = <<~TXT
        → Integration category
        ⇒ Shopify category
      TXT
      assert_equal expected_txt, rule.to_txt
    end

    test "input_txt_equals_output_txt? returns true if the input and output categories have the same full name" do
      rule = MappingRule.new(
        input_category: @shopify_category,
        output_category: {
          "id" => "166",
          "full_name" => "Shopify category",
        },
      )
      assert rule.input_txt_equals_output_txt?
    end

    test "input_txt_equals_output_txt? returns false if the input and output categories have different full names" do
      rule = MappingRule.new(
        input_category: @shopify_category,
        output_category: @integration_category,
      )
      refute rule.input_txt_equals_output_txt?
    end
  end
end
