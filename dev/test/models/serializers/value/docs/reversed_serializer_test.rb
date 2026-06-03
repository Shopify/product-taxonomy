# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Docs
        class ReversedSerializerTest < TestCase
          setup do
            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Color description",
              friendly_id: "color",
              handle: "color",
              values: [],
            )
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Red",
              friendly_id: "color__red",
              handle: "color__red",
            )
            @value.stubs(:primary_attribute).returns(@attribute)
          end

          test "serialize returns the expected JSON structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyValue/1",
              "handle" => "color__red",
              "name" => "Red",
              "friendly_id" => "color__red",
              "attribute" => {
                "handle" => "color",
                "name" => "Color",
              },
            }

            assert_equal expected, ReversedSerializer.serialize(@value)
          end

          test "serialize without a primary attribute returns nil attribute" do
            @value.stubs(:primary_attribute).returns(nil)

            expected = {
              "id" => "gid://shopify/TaxonomyValue/1",
              "handle" => "color__red",
              "name" => "Red",
              "friendly_id" => "color__red",
              "attribute" => nil,
            }

            assert_equal expected, ReversedSerializer.serialize(@value)
          end

          test "serialize_all returns all values" do
            ProductTaxonomy::Value.stubs(:all_values_sorted).returns([@value])

            expected = {
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "handle" => "color__red",
                  "name" => "Red",
                  "friendly_id" => "color__red",
                  "attribute" => {
                    "handle" => "color",
                    "name" => "Color",
                  },
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize_all
          end
        end
      end
    end
  end
end
