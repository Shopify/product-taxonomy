# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Docs
        class SearchSerializerTest < TestCase
          setup do
            @disclosure = ProductTaxonomy::Disclosure.new(
              id: 1,
              public_id: "us-ca-prop65-cancer",
              name: "Cancer",
              internal_label: "Prop 65 cancer",
              description: "Cancer warning",
            )
          end

          test "serialize returns the expected search structure" do
            expected = {
              "searchIdentifier" => "us-ca-prop65-cancer",
              "title" => "Cancer",
              "url" => "?disclosureId=us-ca-prop65-cancer",
              "disclosure" => {
                "public_id" => "us-ca-prop65-cancer",
                "name" => "Cancer",
                "description" => "Cancer warning",
              },
            }

            assert_equal expected, SearchSerializer.serialize(@disclosure)
          end

          test "serialize_all returns all disclosures in search format" do
            ProductTaxonomy::Disclosure.stubs(:all).returns([@disclosure])

            assert_equal [SearchSerializer.serialize(@disclosure)], SearchSerializer.serialize_all
          end
        end
      end
    end
  end
end
