# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class TxtSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )
          end

          test "serialize returns the TXT representation of the return reason" do
            assert_equal "gid://shopify/ReturnReasonDefinition/1 : Test Return Reason", TxtSerializer.serialize(@return_reason)
          end

          test "serialize returns the localized TXT representation of the return reason" do
            stub_localizations

            actual_txt = TxtSerializer.serialize(@return_reason, locale: "fr")
            assert_equal "gid://shopify/ReturnReasonDefinition/1 : Nom en français", actual_txt
          end

          test "serialize_all returns the TXT representation of all return reasons with correct padding" do
            return_reason2 = ProductTaxonomy::ReturnReason.new(
              id: 123456,
              name: "Another Return Reason",
              description: "Another description",
              friendly_id: "another_return_reason",
              handle: "another_handle",
            )
            ProductTaxonomy::ReturnReason.add(@return_reason)
            ProductTaxonomy::ReturnReason.add(return_reason2)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/123456 : Another Return Reason
              gid://shopify/ReturnReasonDefinition/1      : Test Return Reason
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the TXT representation of all return reasons sorted by name" do
            add_return_reasons_for_sorting

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/3 : Aaaa
              gid://shopify/ReturnReasonDefinition/2 : Bbbb
              gid://shopify/ReturnReasonDefinition/1 : Cccc
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all accepts locale parameter" do
            stub_localizations
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/1 : Nom en français
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0", locale: "fr")
          end

          test "serialize applies padding correctly" do
            # Test with specific padding value
            # GID is 37 chars, padding to 50 means 50 - 37 = 13 spaces
            actual_txt = TxtSerializer.serialize(@return_reason, padding: 50)
            expected = "gid://shopify/ReturnReasonDefinition/1             : Test Return Reason"
            assert_equal expected, actual_txt
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                returnreasons:
                  test_return_reason:
                    name: "Nom en français"
                    description: "Description en français"
            YAML
            es_yaml = <<~YAML
              es:
                returnreasons:
                  test_return_reason:
                    name: "Nombre en español"
                    description: "Descripción en español"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "returnreasons", "*.yml"))
              .returns(["fake/path/fr.yml", "fake/path/es.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
            YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))
          end

          def add_return_reasons_for_sorting
            [
              ProductTaxonomy::ReturnReason.new(
                id: 1,
                name: "Cccc",
                description: "Cccc",
                friendly_id: "cccc",
                handle: "cccc",
              ),
              ProductTaxonomy::ReturnReason.new(
                id: 2,
                name: "Bbbb",
                description: "Bbbb",
                friendly_id: "bbbb",
                handle: "bbbb",
              ),
              ProductTaxonomy::ReturnReason.new(
                id: 3,
                name: "Aaaa",
                description: "Aaaa",
                friendly_id: "aaaa",
                handle: "aaaa",
              ),
            ].each { ProductTaxonomy::ReturnReason.add(_1) }
          end
        end
      end
    end
  end
end
