# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Dist
        class JsonSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "color__black",
              handle: "color__black",
            )
            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Defines the primary color or pattern, such as blue or striped",
              friendly_id: "color",
              handle: "color",
              values: [@value],
            )
            @extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Clothing Color",
              description: "Color of the clothing",
              friendly_id: "clothing_color",
              handle: "clothing_color",
              values_from: @attribute,
            )
          end

          test "serialize returns the JSON representation of the attribute" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "name" => "Color",
              "handle" => "color",
              "description" => "Defines the primary color or pattern, such as blue or striped",
              "extended_attributes" => [
                {
                  "name" => "Clothing Color",
                  "handle" => "clothing_color",
                },
              ],
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Black",
                  "handle" => "color__black",
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize(@attribute)
          end

          test "serialize returns the localized JSON representation of the attribute" do
            stub_localizations

            expected_json = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "name" => "Nom en français",
              "handle" => "color",
              "description" => "Description en français",
              "extended_attributes" => [
                {
                  "name" => "Nom en français (extended)",
                  "handle" => "clothing_color",
                },
              ],
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Black",
                  "handle" => "color__black",
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize(@attribute, locale: "fr")
          end

          test "serialize_all returns the JSON representation of all attributes" do
            ProductTaxonomy::Attribute.add(@attribute)
            expected_json = {
              "version" => "1.0",
              "attributes" => [{
                "id" => "gid://shopify/TaxonomyAttribute/1",
                "name" => "Color",
                "handle" => "color",
                "description" => "Defines the primary color or pattern, such as blue or striped",
                "extended_attributes" => [
                  {
                    "name" => "Clothing Color",
                    "handle" => "clothing_color",
                  },
                ],
                "values" => [
                  {
                    "id" => "gid://shopify/TaxonomyValue/1",
                    "name" => "Black",
                    "handle" => "color__black",
                  },
                ],
              }],
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the JSON representation of all attributes sorted by name" do
            add_attributes_for_sorting

            expected_json = {
              "version" => "1.0",
              "attributes" => [
                {
                  "id" => "gid://shopify/TaxonomyAttribute/3",
                  "name" => "Aaaa",
                  "handle" => "aaaa",
                  "description" => "Aaaa",
                  "extended_attributes" => [],
                  "values" => [],
                },
                {
                  "id" => "gid://shopify/TaxonomyAttribute/2",
                  "name" => "Bbbb",
                  "handle" => "bbbb",
                  "description" => "Bbbb",
                  "extended_attributes" => [],
                  "values" => [],
                },
                {
                  "id" => "gid://shopify/TaxonomyAttribute/1",
                  "name" => "Cccc",
                  "handle" => "cccc",
                  "description" => "Cccc",
                  "extended_attributes" => [],
                  "values" => [],
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize calls Value.sort_by_localized_name when sorting is not custom" do
            attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Defines the primary color or pattern, such as blue or striped",
              friendly_id: "color",
              handle: "color",
              values: [@value],
              is_manually_sorted: false,
            )
            ProductTaxonomy::Value.expects(:sort_by_localized_name)
              .with(attribute.values, locale: "en")
              .returns([@value])
            JsonSerializer.serialize(attribute)
          end

          test "serialize does not call Value.sort_by_localized_name when sorting is custom" do
            attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Defines the primary color or pattern, such as blue or striped",
              friendly_id: "color",
              handle: "color",
              values: [@value],
              is_manually_sorted: true,
            )
            Value.expects(:sort_by_localized_name).with(attribute.values, locale: "en").never
            JsonSerializer.serialize(attribute)
          end

          test "serialize returns extended attributes sorted by name" do
            attr = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Defines the primary color or pattern, such as blue or striped",
              friendly_id: "color",
              handle: "color",
              values: [@value],
            )
            ProductTaxonomy::ExtendedAttribute.new(
              name: "Cccc",
              handle: "cccc",
              description: "Cccc",
              friendly_id: "cccc",
              values_from: attr,
            )
            ProductTaxonomy::ExtendedAttribute.new(
              name: "Bbbb",
              handle: "bbbb",
              description: "Bbbb",
              friendly_id: "bbbb",
              values_from: attr,
            )
            ProductTaxonomy::ExtendedAttribute.new(
              name: "Aaaa",
              handle: "aaaa",
              description: "Aaaa",
              friendly_id: "aaaa",
              values_from: attr,
            )

            expected_json = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "name" => "Color",
              "handle" => "color",
              "description" => "Defines the primary color or pattern, such as blue or striped",
              "extended_attributes" => [
                {
                  "name" => "Aaaa",
                  "handle" => "aaaa",
                },
                {
                  "name" => "Bbbb",
                  "handle" => "bbbb",
                },
                {
                  "name" => "Cccc",
                  "handle" => "cccc",
                },
              ],
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Black",
                  "handle" => "color__black",
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize(attr)
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                attributes:
                  color:
                    name: "Nom en français"
                    description: "Description en français"
                  clothing_color:
                    name: "Nom en français (extended)"
                    description: "Description en français (extended)"
            YAML
            es_yaml = <<~YAML
              es:
                attributes:
                  color:
                    name: "Nombre en español"
                    description: "Descripción en español"
                  clothing_color:
                    name: "Nombre en español (extended)"
                    description: "Descripción en español (extended)"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
              .returns(["fake/path/fr.yml", "fake/path/es.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
            YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
              .returns([])
          end

          def add_attributes_for_sorting
            [
              ProductTaxonomy::Attribute.new(id: 1,
                name: "Cccc",
                description: "Cccc",
                friendly_id: "cccc",
                handle: "cccc",
                values: [],
              ),
              ProductTaxonomy::Attribute.new(id: 2,
                name: "Bbbb",
                description: "Bbbb",
                friendly_id: "bbbb",
                handle: "bbbb",
                values: [],
              ),
              ProductTaxonomy::Attribute.new(
                id: 3,
                name: "Aaaa",
                description: "Aaaa",
                friendly_id: "aaaa",
                handle: "aaaa",
                values: [],
              ),
            ].each { ProductTaxonomy::Attribute.add(_1) }
          end
        end
      end
    end
  end
end
