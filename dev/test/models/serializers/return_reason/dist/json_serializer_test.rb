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
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )
          end

          test "serialize returns the JSON representation of the return reason" do
            expected_json = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "name" => "Test Return Reason",
              "handle" => "test_handle",
              "description" => "Test Description",
            }

            assert_equal expected_json, JsonSerializer.serialize(@return_reason)
          end

          test "serialize returns the localized JSON representation of the return reason" do
            stub_localizations

            expected_json = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "name" => "Nom en français",
              "handle" => "test_handle",
              "description" => "Description en français",
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
                  "name" => "Test Return Reason",
                  "handle" => "test_handle",
                  "description" => "Test Description",
                },
              ],
            }

            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all returns the JSON representation of all return reasons sorted by name" do
            add_return_reasons_for_sorting

            expected_json = {
              "version" => "1.0",
              "return_reasons" => [
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/3",
                  "name" => "Aaaa",
                  "handle" => "aaaa",
                  "description" => "Aaaa",
                },
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/2",
                  "name" => "Bbbb",
                  "handle" => "bbbb",
                  "description" => "Bbbb",
                },
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/1",
                  "name" => "Cccc",
                  "handle" => "cccc",
                  "description" => "Cccc",
                },
              ],
            }

            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all accepts locale parameter" do
            stub_localizations
            ProductTaxonomy::ReturnReason.add(@return_reason)

            expected_json = {
              "version" => "1.0",
              "return_reasons" => [
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/1",
                  "name" => "Nom en français",
                  "handle" => "test_handle",
                  "description" => "Description en français",
                },
              ],
            }

            assert_equal expected_json, JsonSerializer.serialize_all(version: "1.0", locale: "fr")
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
