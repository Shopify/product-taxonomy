# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        class LocalizationsSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Damaged",
              description: "Item was damaged",
              friendly_id: "damaged",
              handle: "damaged",
            )
          end

          test "serialize returns the expected data structure for a return reason" do
            expected = {
              "name" => "Damaged",
              "description" => "Item was damaged",
            }

            assert_equal expected, LocalizationsSerializer.serialize(@return_reason)
          end

          test "serialize_all returns all return reasons in localization format" do
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])

            expected = {
              "en" => {
                "return_reasons" => {
                  "damaged" => {
                    "name" => "Damaged",
                    "description" => "Item was damaged",
                  },
                },
              },
            }

            assert_equal expected, LocalizationsSerializer.serialize_all
          end

          test "serialize_all sorts return reasons by friendly_id" do
            return_reason2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Wrong Item",
              description: "Wrong item received",
              friendly_id: "wrong_item",
              handle: "wrong_item",
            )
            return_reason3 = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Arrived Late",
              description: "Item arrived late",
              friendly_id: "arrived_late",
              handle: "arrived_late",
            )

            # Add in non-alphabetical order
            ProductTaxonomy::ReturnReason.stubs(:all).returns([return_reason2, @return_reason, return_reason3])

            result = LocalizationsSerializer.serialize_all
            keys = result["en"]["return_reasons"].keys

            # Should be sorted alphabetically by friendly_id
            assert_equal ["arrived_late", "damaged", "wrong_item"], keys
          end

          test "serialize respects locale parameter" do
            stub_localizations

            result = LocalizationsSerializer.serialize(@return_reason, locale: "fr")

            expected = {
              "name" => "Endommagé",
              "description" => "L'article était endommagé",
            }

            assert_equal expected, result
          end

          test "serialize_all respects locale parameter" do
            stub_localizations
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])

            result = LocalizationsSerializer.serialize_all(locale: "fr")

            expected = {
              "fr" => {
                "return_reasons" => {
                  "damaged" => {
                    "name" => "Endommagé",
                    "description" => "L'article était endommagé",
                  },
                },
              },
            }

            assert_equal expected, result
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
