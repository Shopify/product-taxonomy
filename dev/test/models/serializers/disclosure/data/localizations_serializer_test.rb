# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Data
        class LocalizationsSerializerTest < TestCase
          setup do
            @leaf = ProductTaxonomy::Disclosure.new(
              id: 2,
              public_id: "us-cpsc-choking_small_parts",
              parent_public_id: "choking_hazard",
              name: "Choking Hazard — Small Parts (US)",
              internal_label: "Choking Hazard — Small Parts (US)",
              description: nil,
              title: "Choking Hazard: Small Parts",
              content: "Not for children under 3 years.",
            )
            @group = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "choking_hazard",
              name: "Choking hazards",
              internal_label: "Choking hazards",
              description: "Choking and suffocation hazards for children",
            )
          end

          test "serialize_all returns localized fields keyed by public_id, sorted by public_id" do
            # Add out of alphabetical order to ensure serialize_all sorts.
            ProductTaxonomy::Disclosure.add(@leaf)
            ProductTaxonomy::Disclosure.add(@group)

            expected = {
              "en" => {
                "disclosures" => {
                  "choking_hazard" => {
                    "name" => "Choking hazards",
                    "description" => "Choking and suffocation hazards for children",
                    "title" => nil,
                    "content" => nil,
                  },
                  "us-cpsc-choking_small_parts" => {
                    "name" => "Choking Hazard — Small Parts (US)",
                    "description" => nil,
                    "title" => "Choking Hazard: Small Parts",
                    "content" => "Not for children under 3 years.",
                  },
                },
              },
            }
            assert_equal expected, LocalizationsSerializer.serialize_all
            assert_equal ["choking_hazard", "us-cpsc-choking_small_parts"], LocalizationsSerializer.serialize_all["en"]["disclosures"].keys
          end
        end
      end
    end
  end
end
