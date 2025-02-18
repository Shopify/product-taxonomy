# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Dist
        class TxtSerializerTest < TestCase
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
          end

          test "serialize returns the TXT representation of the attribute" do
            assert_equal "gid://shopify/TaxonomyAttribute/1 : Color", TxtSerializer.serialize(@attribute)
          end

          test "serialize returns the localized TXT representation of the attribute" do
            stub_localizations

            actual_txt = TxtSerializer.serialize(@attribute, locale: "fr")
            assert_equal "gid://shopify/TaxonomyAttribute/1 : Nom en français", actual_txt
          end

          test "serialize_all returns the TXT representation of all attributes with correct padding" do
            attribute2 = ProductTaxonomy::Attribute.new(
              id: 123456,
              name: "Pattern",
              description: "Describes the design or motif of a product, such as floral or striped",
              friendly_id: "pattern",
              handle: "pattern",
              values: [],
            )
            ProductTaxonomy::Attribute.add(@attribute)
            ProductTaxonomy::Attribute.add(attribute2)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Attributes: 1.0
              # Format: {GID} : {Attribute name}

              gid://shopify/TaxonomyAttribute/1      : Color
              gid://shopify/TaxonomyAttribute/123456 : Pattern
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the TXT representation of all attributes sorted by name" do
            add_attributes_for_sorting

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Attributes: 1.0
              # Format: {GID} : {Attribute name}

              gid://shopify/TaxonomyAttribute/3 : Aaaa
              gid://shopify/TaxonomyAttribute/2 : Bbbb
              gid://shopify/TaxonomyAttribute/1 : Cccc
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
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
