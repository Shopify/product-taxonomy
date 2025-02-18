# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Dist
        class TxtSerializerTest < TestCase
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

          test "serialize returns the text representation of the value" do
            expected_txt = "gid://shopify/TaxonomyValue/1 : Black [Color]"
            assert_equal expected_txt, TxtSerializer.serialize(@value)
          end

          test "serialize returns the localized text representation of the value" do
            stub_localizations

            expected_txt = "gid://shopify/TaxonomyValue/1 : Nom en français [Color]"
            assert_equal expected_txt, TxtSerializer.serialize(@value, locale: "fr")
          end

          test "serialize_all returns the text representation of all values with correct padding" do
            value2 = ProductTaxonomy::Value.new(
              id: 123456,
              name: "Blue",
              friendly_id: "color__blue",
              handle: "color__blue"
            )
            ProductTaxonomy::Value.add(@value)
            ProductTaxonomy::Value.add(value2)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Attribute Values: 1.0
              # Format: {GID} : {Value name} [{Attribute name}]

              gid://shopify/TaxonomyValue/1      : Black [Color]
              gid://shopify/TaxonomyValue/123456 : Blue [Color]
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the text representation of all values sorted by name with 'Other' at the end" do
            add_values_for_sorting

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Attribute Values: 1.0
              # Format: {GID} : {Value name} [{Attribute name}]

              gid://shopify/TaxonomyValue/4 : Aaaa [Color]
              gid://shopify/TaxonomyValue/2 : Bbbb [Color]
              gid://shopify/TaxonomyValue/1 : Cccc [Color]
              gid://shopify/TaxonomyValue/3 : Other [Color]
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all sorts localized values according to their sort order in English" do
            add_values_for_sorting
            stub_localizations_for_sorting

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Attribute Values: 1.0
              # Format: {GID} : {Value name} [{Attribute name}]

              gid://shopify/TaxonomyValue/4 : Zzzz [Color]
              gid://shopify/TaxonomyValue/2 : Xxxx [Color]
              gid://shopify/TaxonomyValue/1 : Yyyy [Color]
              gid://shopify/TaxonomyValue/3 : Autre [Color]
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0", locale: "fr")
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
