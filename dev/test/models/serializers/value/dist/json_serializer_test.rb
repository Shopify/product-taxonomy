# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Dist
        class JsonSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "color__black",
              handle: "color__black"
            )
            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              friendly_id: "color",
              handle: "color",
              description: "Color",
              values: [@value]
            )
            ProductTaxonomy::Attribute.add(@attribute)
          end

          test "serialize returns the JSON representation of the value" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyValue/1",
              "name" => "Black",
              "handle" => "color__black"
            }
            assert_equal expected_json, JsonSerializer.serialize(@value)
          end

          test "serialize returns the localized JSON representation of the value" do
            stub_localizations

            expected_json = {
              "id" => "gid://shopify/TaxonomyValue/1",
              "name" => "Nom en français",
              "handle" => "color__black"
            }
            assert_equal expected_json, JsonSerializer.serialize(@value, locale: "fr")
          end

          test "serialize_all returns the JSON representation of all values" do
            ProductTaxonomy::Value.add(@value)

            expected_json = {
              "version" => "1.0",
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Black",
                  "handle" => "color__black"
                }
              ]
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the JSON representation of all values sorted by name with 'Other' at the end" do
            add_values_for_sorting

            expected_json = {
              "version" => "1.0",
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/4",
                  "name" => "Aaaa",
                  "handle" => "color__aaa"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/2",
                  "name" => "Bbbb",
                  "handle" => "color__bbb"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Cccc",
                  "handle" => "color__ccc"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/3",
                  "name" => "Other",
                  "handle" => "color__other"
                }
              ]
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all sorts localized values according to their sort order in English" do
            add_values_for_sorting
            stub_localizations_for_sorting

            expected_json = {
              "version" => "1.0",
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/4",
                  "name" => "Zzzz",
                  "handle" => "color__aaa"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/2",
                  "name" => "Xxxx",
                  "handle" => "color__bbb"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Yyyy",
                  "handle" => "color__ccc"
                },
                {
                  "id" => "gid://shopify/TaxonomyValue/3",
                  "name" => "Autre",
                  "handle" => "color__other"
                }
              ]
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0", locale: "fr")
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                values:
                  color__black:
                    name: "Nom en français"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
              .returns(["fake/path/fr.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))

            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
              .returns([])
          end

          def add_values_for_sorting
            [
              ProductTaxonomy::Value.new(id: 1, name: "Cccc", friendly_id: "color__ccc", handle: "color__ccc"),
              ProductTaxonomy::Value.new(id: 2, name: "Bbbb", friendly_id: "color__bbb", handle: "color__bbb"),
              ProductTaxonomy::Value.new(id: 3, name: "Other", friendly_id: "color__other", handle: "color__other"),
              ProductTaxonomy::Value.new(id: 4, name: "Aaaa", friendly_id: "color__aaa", handle: "color__aaa")
            ].each { ProductTaxonomy::Value.add(_1) }
          end

          def stub_localizations_for_sorting
            fr_yaml = <<~YAML
              fr:
                values:
                  color__aaa:
                    name: "Zzzz"
                  color__bbb:
                    name: "Xxxx"
                  color__ccc:
                    name: "Yyyy"
                  color__other:
                    name: "Autre"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
              .returns(["fake/path/fr.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))

            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
              .returns([])
          end
        end
      end
    end
  end
end
