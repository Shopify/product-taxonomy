# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Dist
        class TxtSerializerTest < TestCase
          setup do
            @group = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "choking_hazard",
              name: "Choking hazards",
              internal_label: "Choking hazards",
            )
            @leaf = ProductTaxonomy::Disclosure.new(
              id: 2,
              public_id: "us-cpsc-choking_small_parts",
              parent_public_id: "choking_hazard",
              name: "Choking Hazard — Small Parts (US)",
              internal_label: "Choking Hazard — Small Parts (US)",
              jurisdictions: ["US"],
              legal_citation: "16 CFR 1501",
              title: "Choking Hazard: Small Parts",
              content: "Not for children under 3 years.",
              source: "https://www.ecfr.gov/current/title-16/part-1501",
              display_preferences: { "surfaces" => ["product_page"] },
            )
          end

          test "serialize returns the text representation of the disclosure" do
            expected_txt = "gid://shopify/TaxonomyDisclosure/1 : Choking hazards"
            assert_equal expected_txt, TxtSerializer.serialize(@group)
          end

          test "serialize returns the localized text representation of the disclosure" do
            stub_localizations

            expected_txt = "gid://shopify/TaxonomyDisclosure/1 : Risques d'étouffement"
            assert_equal expected_txt, TxtSerializer.serialize(@group, locale: "fr")
          end

          test "serialize_all returns the text representation of all disclosures" do
            ProductTaxonomy::Disclosure.add(@group)
            ProductTaxonomy::Disclosure.add(@leaf)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Disclosures: 1.0
              # Format: {GID} : {Disclosure name}

              gid://shopify/TaxonomyDisclosure/1 : Choking hazards
              gid://shopify/TaxonomyDisclosure/2 : Choking Hazard — Small Parts (US)
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all pads GIDs to the longest GID length" do
            wide = ProductTaxonomy::Disclosure.new(
              id: 123456,
              public_id: "wide",
              name: "Wide",
              internal_label: "Wide",
            )
            ProductTaxonomy::Disclosure.add(@group)
            ProductTaxonomy::Disclosure.add(wide)

            expected_txt = <<~TXT
              # Shopify Product Taxonomy - Disclosures: 1.0
              # Format: {GID} : {Disclosure name}

              gid://shopify/TaxonomyDisclosure/1      : Choking hazards
              gid://shopify/TaxonomyDisclosure/123456 : Wide
            TXT
            assert_equal expected_txt.strip, TxtSerializer.serialize_all(version: "1.0")
          end

          test "serialize_all includes version in header" do
            ProductTaxonomy::Disclosure.add(@group)

            result = TxtSerializer.serialize_all(version: "2.5.0")

            assert_includes result, "Disclosures: 2.5.0"
          end

          test "serialize respects padding parameter" do
            expected_txt = "#{"gid://shopify/TaxonomyDisclosure/1".ljust(50)} : Choking hazards"
            assert_equal expected_txt, TxtSerializer.serialize(@group, padding: 50)
          end

          private

          def stub_localizations
            fr_yaml = <<~YAML
              fr:
                disclosures:
                  choking_hazard:
                    name: "Risques d'étouffement"
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
