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
            )
          end

          test "serialize returns the expected structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyDisclosure/1",
              "public_id" => "us-ca-prop65-cancer",
              "name" => "Cancer",
              "description" => "Cancer warning",
              "kind" => "display",
              "parent_public_id" => nil,
              "parent_name" => nil,
              "jurisdictions" => ["US-CA"],
              "legal_citation" => "Cal. Code Regs. tit. 27",
            }

            assert_equal expected, BaseSerializer.serialize(@disclosure)
          end

          test "serialize marks a disclosure that has children as a grouping node" do
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
            ProductTaxonomy::Disclosure.stubs(:all).returns([group, child])

            assert_equal "grouping", BaseSerializer.serialize(group)["kind"]
            assert_equal "display", BaseSerializer.serialize(child)["kind"]
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
