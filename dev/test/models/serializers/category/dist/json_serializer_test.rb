# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Dist
        class JsonSerializerTest < TestCase
          setup do
            @root = ProductTaxonomy::Category.new(id: "aa", name: "Root")
            @child = ProductTaxonomy::Category.new(id: "aa-1", name: "Child")
            @root.add_child(@child)
            @grandchild = ProductTaxonomy::Category.new(id: "aa-1-1", name: "Grandchild")
            @child.add_child(@grandchild)
          end

          test "serialize returns the JSON representation of the category for root node" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyCategory/aa",
              "level" => 0,
              "name" => "Root",
              "full_name" => "Root",
              "parent_id" => nil,
              "attributes" => [],
              "children" => [{
                "id" => "gid://shopify/TaxonomyCategory/aa-1",
                "name" => "Child",
              }],
              "ancestors" => [],
              "return_reasons" => [],
            }
            assert_equal expected_json, JsonSerializer.serialize(@root)
          end

          test "serialize returns the JSON representation of the category for child node" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyCategory/aa-1",
              "level" => 1,
              "name" => "Child",
              "full_name" => "Root > Child",
              "parent_id" => "gid://shopify/TaxonomyCategory/aa",
              "attributes" => [],
              "children" => [{
                "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
                "name" => "Grandchild",
              }],
              "ancestors" => [{
                "id" => "gid://shopify/TaxonomyCategory/aa",
                "name" => "Root",
              }],
              "return_reasons" => [],
            }
            assert_equal expected_json, JsonSerializer.serialize(@child)
          end

          test "serialize returns the JSON representation of the category for grandchild node" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
              "level" => 2,
              "name" => "Grandchild",
              "full_name" => "Root > Child > Grandchild",
              "parent_id" => "gid://shopify/TaxonomyCategory/aa-1",
              "attributes" => [],
              "children" => [],
              "ancestors" => [
                {
                  "id" => "gid://shopify/TaxonomyCategory/aa-1",
                  "name" => "Child",
                },
                {
                  "id" => "gid://shopify/TaxonomyCategory/aa",
                  "name" => "Root",
                },
              ],
              "return_reasons" => [],
            }
            assert_equal expected_json, JsonSerializer.serialize(@grandchild)
          end

          test "serialize returns the localized JSON representation of the category for root node" do
            stub_localizations

            expected_json = {
              "id" => "gid://shopify/TaxonomyCategory/aa",
              "level" => 0,
              "name" => "Root en français",
              "full_name" => "Root en français",
              "parent_id" => nil,
              "attributes" => [],
              "children" => [{
                "id" => "gid://shopify/TaxonomyCategory/aa-1",
                "name" => "Child en français",
              }],
              "ancestors" => [],
              "return_reasons" => [],
            }
            assert_equal expected_json, JsonSerializer.serialize(@root, locale: "fr")
          end

          test "serialize returns the JSON representation of the category with children sorted by name" do
            yaml_content = <<~YAML
              ---
              - id: aa
                name: Root
                children:
                - aa-1
                - aa-2
                - aa-3
                attributes: []
              - id: aa-1
                name: Cccc
                children: []
                attributes: []
              - id: aa-2
                name: Bbbb
                children: []
                attributes: []
              - id: aa-3
                name: Aaaa
                children: []
                attributes: []
            YAML

            ProductTaxonomy::Category.load_from_source(YAML.safe_load(yaml_content))

            actual_json = JsonSerializer
              .serialize(ProductTaxonomy::Category.verticals.first)["children"]
              .map { _1["name"] }
            assert_equal ["Aaaa", "Bbbb", "Cccc"], actual_json
          end

          test "serialize returns the JSON representation of the category with attributes sorted by name" do
            value = ProductTaxonomy::Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
            ProductTaxonomy::Value.add(value)
            attribute1 = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Aaaa",
              friendly_id: "aaaa",
              handle: "aaaa",
              description: "Aaaa",
              values: [value],
            )
            attribute2 = ProductTaxonomy::Attribute.new(
              id: 2,
              name: "Bbbb",
              friendly_id: "bbbb",
              handle: "bbbb",
              description: "Bbbb",
              values: [value],
            )
            attribute3 = ProductTaxonomy::Attribute.new(
              id: 3,
              name: "Cccc",
              friendly_id: "cccc",
              handle: "cccc",
              description: "Cccc",
              values: [value],
            )
            ProductTaxonomy::Attribute.add(attribute1)
            ProductTaxonomy::Attribute.add(attribute2)
            ProductTaxonomy::Attribute.add(attribute3)
            yaml_content = <<~YAML
              ---
              - id: aa
                name: Root
                attributes:
                - cccc
                - bbbb
                - aaaa
                children: []
            YAML

            ProductTaxonomy::Category.load_from_source(YAML.safe_load(yaml_content))
            actual_json = JsonSerializer
              .serialize(ProductTaxonomy::Category.verticals.first)["attributes"]
              .map { _1["name"] }
            assert_equal ["Aaaa", "Bbbb", "Cccc"], actual_json
          end

          test "serialize preserves return_reasons order from YAML" do
            rr1 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Zzz",
              description: "Zzz",
              friendly_id: "zzz",
              handle: "zzz",
            )
            rr2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Aaa",
              description: "Aaa",
              friendly_id: "aaa",
              handle: "aaa",
            )
            ProductTaxonomy::ReturnReason.add(rr1)
            ProductTaxonomy::ReturnReason.add(rr2)

            yaml_content = <<~YAML
              ---
              - id: aa
                name: Root
                children: []
                attributes: []
                return_reasons:
                - zzz
                - aaa
            YAML

            ProductTaxonomy::Category.load_from_source(YAML.safe_load(yaml_content))
            actual_handles = JsonSerializer
              .serialize(ProductTaxonomy::Category.verticals.first)["return_reasons"]
              .map { _1["handle"] }

            assert_equal ["zzz", "aaa"], actual_handles
          end

          test "serialize_all returns the JSON representation of all categories" do
            stub_localizations
            ProductTaxonomy::Category.stubs(:verticals).returns([@root])

            expected_json = {
              "version" => "1.0",
              "verticals" => [{
                "name" => "Root",
                "prefix" => "aa",
                "categories" => [
                  {
                    "id" => "gid://shopify/TaxonomyCategory/aa",
                    "level" => 0,
                    "name" => "Root",
                    "full_name" => "Root",
                    "parent_id" => nil,
                    "attributes" => [],
                    "children" => [{ "id" => "gid://shopify/TaxonomyCategory/aa-1", "name" => "Child" }],
                    "ancestors" => [],
                    "return_reasons" => [],
                  },
                  {
                    "id" => "gid://shopify/TaxonomyCategory/aa-1",
                    "level" => 1,
                    "name" => "Child",
                    "full_name" => "Root > Child",
                    "parent_id" => "gid://shopify/TaxonomyCategory/aa",
                    "attributes" => [],
                    "children" => [{ "id" => "gid://shopify/TaxonomyCategory/aa-1-1", "name" => "Grandchild" }],
                    "ancestors" => [{ "id" => "gid://shopify/TaxonomyCategory/aa", "name" => "Root" }],
                    "return_reasons" => [],
                  },
                  {
                    "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
                    "level" => 2,
                    "name" => "Grandchild",
                    "full_name" => "Root > Child > Grandchild",
                    "parent_id" => "gid://shopify/TaxonomyCategory/aa-1",
                    "attributes" => [],
                    "children" => [],
                    "ancestors" => [
                      { "id" => "gid://shopify/TaxonomyCategory/aa-1", "name" => "Child" },
                      { "id" => "gid://shopify/TaxonomyCategory/aa", "name" => "Root" },
                    ],
                    "return_reasons" => [],
                  },
                ],
              }],
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                categories:
                  aa:
                    name: "Root en français"
                  aa-1:
                    name: "Child en français"
                  aa-1-1:
                    name: "Grandchild en français"
            YAML
            es_yaml = <<~YAML
              es:
                categories:
                  aa:
                    name: "Root en español"
                  aa-1:
                    name: "Child en español"
                  aa-1-1:
                    name: "Grandchild en español"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "categories", "*.yml"))
              .returns(["fake/path/fr.yml", "fake/path/es.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
            YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
              .returns([])
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
              .returns([])
          end
        end
      end
    end
  end
end
