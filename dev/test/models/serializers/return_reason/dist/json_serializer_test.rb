# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Dist
        class JsonSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Damaged",
              description: "Item was damaged",
              friendly_id: "damaged",
              handle: "damaged",
            )
          end

          test "serialize returns the JSON representation of the return reason" do
            expected_json = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "name" => "Damaged",
              "handle" => "damaged",
              "description" => "Item was damaged",
            }
            assert_equal expected_json, JsonSerializer.serialize(@return_reason)
          end

          test "serialize returns the localized JSON representation of the return reason" do
            stub_localizations

            expected_json = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "name" => "Endommagé",
              "handle" => "damaged",
              "description" => "L'article était endommagé",
            }
            assert_equal expected_json, JsonSerializer.serialize(@return_reason, locale: "fr")
          end

          test "serialize_all returns the JSON representation of all return reasons" do
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_json = {
              "version" => "1.0",
              "return_reasons" => [
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/1",
                  "name" => "Damaged",
                  "handle" => "damaged",
                  "description" => "Item was damaged",
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the localized JSON representation of all return reasons" do
            stub_localizations
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_json = {
              "version" => "1.0",
              "return_reasons" => [
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/1",
                  "name" => "Endommagé",
                  "handle" => "damaged",
                  "description" => "L'article était endommagé",
                },
              ],
            }
            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0", locale: "fr")
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

            # Add out-of-alphabetical order to ensure we don't sort by name.
            ProductTaxonomy::ReturnReason.add(rr1)
            ProductTaxonomy::ReturnReason.add(rr2)

            json = JsonSerializer.serialize_all(version: "1.0", locale: "en")
            handles = json.fetch("return_reasons").map { _1.fetch("handle") }

            assert_equal ["zzz", "aaa"], handles
          end

          test "serialize_all includes version in output" do
            ProductTaxonomy::ReturnReason.add(@return_reason)

            result = JsonSerializer.serialize_all(version: "2.5.0")

            assert_equal "2.5.0", result["version"]
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
