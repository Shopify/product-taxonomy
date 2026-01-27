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
              name: "Damaged",
              description: "Item was damaged",
              friendly_id: "damaged",
              handle: "damaged",
            )
          end

          test "serialize returns the text representation of the return reason" do
            expected_txt = "gid://shopify/ReturnReasonDefinition/1 : Damaged"
            assert_equal expected_txt, TxtSerializer.serialize(@return_reason)
          end

          test "serialize returns the localized text representation of the return reason" do
            stub_localizations

            expected_txt = "gid://shopify/ReturnReasonDefinition/1 : Endommagé"
            assert_equal expected_txt, TxtSerializer.serialize(@return_reason, locale: "fr")
          end

          test "serialize_all returns the text representation of all return reasons" do
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/1 : Damaged
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the text representation with correct padding" do
            return_reason2 = ProductTaxonomy::ReturnReason.new(
              id: 123456,
              name: "Wrong Item",
              description: "Wrong item received",
              friendly_id: "wrong_item",
              handle: "wrong_item",
            )
            ProductTaxonomy::ReturnReason.add(@return_reason)
            ProductTaxonomy::ReturnReason.add(return_reason2)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/1      : Damaged
              gid://shopify/ReturnReasonDefinition/123456 : Wrong Item
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the localized text representation of all return reasons" do
            stub_localizations
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Return Reasons: 1.0
              # Format: {GID} : {Return reason name}

              gid://shopify/ReturnReasonDefinition/1 : Endommagé
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0", locale: "fr")
          end

          test "serialize_all preserves return reasons source order" do
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

            txt = TxtSerializer.serialize_all(version: "1.0", locale: "en")
            lines = txt.split("\n").reject { _1.start_with?("#") || _1.strip.empty? }

            # First non-header line should correspond to rr1 (zzz), then rr2 (aaa).
            assert_includes lines.first, "ReturnReasonDefinition/1"
            assert_includes lines.first, "Zzz"
            assert_includes lines.second, "ReturnReasonDefinition/2"
            assert_includes lines.second, "Aaa"
          end

          test "serialize_all includes version in header" do
            ProductTaxonomy::ReturnReason.add(@return_reason)

            result = TxtSerializer.serialize_all(version: "2.5.0")

            assert_includes result, "Return Reasons: 2.5.0"
          end

          test "serialize respects padding parameter" do
            expected_txt = "gid://shopify/ReturnReasonDefinition/1             : Damaged"
            assert_equal expected_txt, TxtSerializer.serialize(@return_reason, padding: 50)
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                return_reasons:
                  damaged:
                    name: "Endommagé"
                    description: "L'article était endommagé"
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "return_reasons", "*.yml"))
              .returns(["fake/path/fr.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
          end
        end
      end
    end
  end
end
