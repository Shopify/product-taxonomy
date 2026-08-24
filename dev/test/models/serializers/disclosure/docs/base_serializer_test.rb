# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Docs
        class BaseSerializerTest < TestCase
          setup do
            @disclosure = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "us-ca-prop65-cancer",
              name: "Cancer",
              internal_label: "Prop 65 cancer",
              description: "Cancer warning",
              jurisdictions: ["US-CA"],
              legal_citation: "Cal. Code Regs. tit. 27",
              title: "Prop 65 Cancer Warning",
              content: "**WARNING:** Cancer",
              source: "https://oehha.ca.gov/proposition-65",
              symbol: "https://cdn.shopify.com/static/product-disclosures/default-warning-yellow.png",
              display_requirements: "Display the disclosure pre-purchase.",
            )
          end

          test "serialize returns the expected structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyDisclosure/1",
              "public_id" => "us-ca-prop65-cancer",
              "name" => "Cancer",
              "description" => "Cancer warning",
              "parent_public_id" => nil,
              "jurisdictions" => ["US-CA"],
              "legal_citation" => "Cal. Code Regs. tit. 27",
              "title" => "Prop 65 Cancer Warning",
              "content" => "**WARNING:** Cancer",
              "source" => "https://oehha.ca.gov/proposition-65",
              "symbol" => "https://cdn.shopify.com/static/product-disclosures/default-warning-yellow.png",
              "display_requirements" => "Display the disclosure pre-purchase.",
              "children" => [],
            }

            assert_equal expected, BaseSerializer.serialize(@disclosure)
          end

          test "serialize returns the parent public id of a child disclosure" do
            child = ProductTaxonomy::Disclosure.new(
              id: 3,
              public_id: "us-ca-prop65-birth_defects",
              name: "Birth defects",
              internal_label: "Prop 65 birth defects",
              parent_public_id: "us-ca-prop65",
            )

            assert_equal "us-ca-prop65", BaseSerializer.serialize(child)["parent_public_id"]
          end

          test "serialize lists the children of a grouping disclosure" do
            group = ProductTaxonomy::Disclosure.new(
              id: 2,
              public_id: "us-ca-prop65",
              name: "Proposition 65",
              internal_label: "Proposition 65",
            )
            child = ProductTaxonomy::Disclosure.new(
              id: 3,
              public_id: "us-ca-prop65-birth_defects",
              name: "Birth defects",
              internal_label: "Prop 65 birth defects",
              parent_public_id: "us-ca-prop65",
            )
            ProductTaxonomy::Disclosure.add(group)
            ProductTaxonomy::Disclosure.add(child)

            expected_children = [{ "public_id" => "us-ca-prop65-birth_defects", "name" => "Birth defects" }]
            assert_equal expected_children, BaseSerializer.serialize(group)["children"]
            assert_empty BaseSerializer.serialize(child)["children"]
          end

          test "serialize_all returns all disclosures" do
            ProductTaxonomy::Disclosure.stubs(:all).returns([@disclosure])

            assert_equal [BaseSerializer.serialize(@disclosure)], BaseSerializer.serialize_all
          end
        end
      end
    end
  end
end
