# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Data
        class DataSerializerTest < TestCase
          setup do
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
              disclosure_attributes: [],
              disclosure_attribute_values: [],
            )
          end

          test "serialize returns the source data representation of the disclosure" do
            expected = {
              "id" => 2,
              "public_id" => "us-cpsc-choking_small_parts",
              "parent_public_id" => "choking_hazard",
              "name" => "Choking Hazard — Small Parts (US)",
              "internal_label" => "Choking Hazard — Small Parts (US)",
              "description" => nil,
              "jurisdictions" => ["US"],
              "legal_citation" => "16 CFR 1501",
              "symbol" => nil,
              "display_requirements" => nil,
              "display_preferences" => { "surfaces" => ["product_page"] },
              "title" => "Choking Hazard: Small Parts",
              "content" => "Not for children under 3 years.",
              "source" => "https://www.ecfr.gov/current/title-16/part-1501",
              "disclosure_attributes" => [],
              "disclosure_attribute_values" => [],
            }
            assert_equal expected, DataSerializer.serialize(@leaf)
          end

          test "serialize omits optional keys that are nil, matching the authored file shape" do
            group = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "choking_hazard",
              name: "Choking hazards",
              internal_label: "Choking hazards",
            )

            serialized = DataSerializer.serialize(group)

            refute_includes serialized.keys, "jurisdictions"
            refute_includes serialized.keys, "display_preferences"
            assert_includes serialized.keys, "title" # common keys stay present even when nil
          end

          test "serialize_all sorts disclosures by id" do
            second = ProductTaxonomy::Disclosure.new(id: 12, public_id: "chemical_exposure", name: "Chemical exposures", internal_label: "Chemical exposures")
            first = ProductTaxonomy::Disclosure.new(id: 1, public_id: "choking_hazard", name: "Choking hazards", internal_label: "Choking hazards")

            # Add out of id order to ensure serialize_all sorts.
            ProductTaxonomy::Disclosure.add(second)
            ProductTaxonomy::Disclosure.add(first)

            assert_equal [1, 12], DataSerializer.serialize_all.map { _1.fetch("id") }
          end
        end
      end
    end
  end
end
