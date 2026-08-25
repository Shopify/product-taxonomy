# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Dist
        class JsonSerializerTest < TestCase
          setup do
            @group = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "choking_hazard",
              name: "Choking hazards",
              internal_label: "Choking hazards",
              description: "Choking and suffocation hazards for children",
            )
            @leaf = ProductTaxonomy::Disclosure.new(
              id: 2,
              public_id: "us-cpsc-choking_small_parts",
              parent_public_id: "choking_hazard",
              name: "Choking Hazard — Small Parts (US)",
              internal_label: "Choking Hazard — Small Parts (US)",
              jurisdictions: ["US"],
              disclosure_attributes: [],
              disclosure_attribute_values: [],
              legal_citation: "16 CFR 1501",
              symbol: "https://cdn.shopify.com/static/product-disclosures/default-warning-white.png",
              display_requirements: "Display the disclosure pre-purchase.",
              title: "Choking Hazard: Small Parts",
              content: "Not for children under 3 years.",
              source: "https://www.ecfr.gov/current/title-16/part-1501",
              display_preferences: { "surfaces" => ["product_page"] },
            )
          end

          test "serialize returns the JSON representation of a leaf disclosure" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyDisclosure/2",
              "public_id" => "us-cpsc-choking_small_parts",
              "parent_public_id" => "choking_hazard",
              "name" => "Choking Hazard — Small Parts (US)",
              "internal_label" => "Choking Hazard — Small Parts (US)",
              "description" => nil,
              "jurisdictions" => ["US"],
              "legal_citation" => "16 CFR 1501",
              "title" => "Choking Hazard: Small Parts",
              "content" => "Not for children under 3 years.",
              "source" => "https://www.ecfr.gov/current/title-16/part-1501",
              "symbol" => "https://cdn.shopify.com/static/product-disclosures/default-warning-white.png",
              "display_requirements" => "Display the disclosure pre-purchase.",
              "display_preferences" => { "surfaces" => ["product_page"] },
              "disclosure_attributes" => [],
              "disclosure_attribute_values" => [],
            }
            assert_equal expected_json, JsonSerializer.serialize(@leaf)
          end

          test "serialize returns nil leaf-only fields for a grouping disclosure" do
            expected_json = {
              "id" => "gid://shopify/TaxonomyDisclosure/1",
              "public_id" => "choking_hazard",
              "parent_public_id" => nil,
              "name" => "Choking hazards",
              "internal_label" => "Choking hazards",
              "description" => "Choking and suffocation hazards for children",
              "jurisdictions" => nil,
              "legal_citation" => nil,
              "title" => nil,
              "content" => nil,
              "source" => nil,
              "symbol" => nil,
              "display_requirements" => nil,
              "display_preferences" => nil,
              "disclosure_attributes" => nil,
              "disclosure_attribute_values" => nil,
            }
            assert_equal expected_json, JsonSerializer.serialize(@group)
          end

          test "serialize exposes every disclosure field" do
            serialized = JsonSerializer.serialize(@leaf)

            assert_includes serialized.keys, "internal_label"
            assert_includes serialized.keys, "disclosure_attributes"
            assert_includes serialized.keys, "disclosure_attribute_values"
          end

          test "serialize returns the localized JSON representation of the disclosure" do
            stub_localizations

            serialized = JsonSerializer.serialize(@leaf, locale: "fr")

            assert_equal "Risque d'étouffement — Petites pièces (É-U)", serialized["name"]
            assert_equal "Risque d'étouffement : petites pièces", serialized["title"]
            assert_equal "Ne convient pas aux enfants de moins de 3 ans.", serialized["content"]
          end

          test "serialize_all returns the JSON representation of all disclosures" do
            ProductTaxonomy::Disclosure.add(@group)
            ProductTaxonomy::Disclosure.add(@leaf)

            result = JsonSerializer.serialize_all(version: "1.0")

            assert_equal "1.0", result["version"]
            assert_equal 2, result["disclosures"].size
            assert_equal(
              ["choking_hazard", "us-cpsc-choking_small_parts"],
              result["disclosures"].map { _1.fetch("public_id") },
            )
          end

          test "serialize_all preserves disclosures source order" do
            zzz = ProductTaxonomy::Disclosure.new(id: 1, public_id: "zzz", name: "Zzz", internal_label: "Zzz")
            aaa = ProductTaxonomy::Disclosure.new(id: 2, public_id: "aaa", name: "Aaa", internal_label: "Aaa")

            # Add out-of-alphabetical order to ensure we don't sort by name.
            ProductTaxonomy::Disclosure.add(zzz)
            ProductTaxonomy::Disclosure.add(aaa)

            json = JsonSerializer.serialize_all(version: "1.0", locale: "en")
            public_ids = json.fetch("disclosures").map { _1.fetch("public_id") }

            assert_equal ["zzz", "aaa"], public_ids
          end

          test "serialize_all includes version in output" do
            ProductTaxonomy::Disclosure.add(@group)

            result = JsonSerializer.serialize_all(version: "2.5.0")

            assert_equal "2.5.0", result["version"]
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                disclosures:
                  us-cpsc-choking_small_parts:
                    name: "Risque d'étouffement — Petites pièces (É-U)"
                    title: "Risque d'étouffement : petites pièces"
                    content: "Ne convient pas aux enfants de moins de 3 ans."
            YAML
            Dir.stubs(:glob)
              .with(File.join(ProductTaxonomy.data_path, "localizations", "disclosures", "*.yml"))
              .returns(["fake/path/fr.yml"])
            YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
          end
        end
      end
    end
  end
end
