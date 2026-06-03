# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Docs
        class SearchSerializerTest < TestCase
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
            @attribute.stubs(:values).returns([@value])
            @value.stubs(:primary_attribute).returns(@attribute)
          end

          test "serialize returns the expected search structure" do
            expected = {
              "searchIdentifier" => "color__red",
              "title" => "Red [Color]",
              "url" => "?valueHandle=color__red",
              "value" => {
                "handle" => "color__red",
                "name" => "Red",
                "attribute_handle" => "color",
              },
            }

            assert_equal expected, SearchSerializer.serialize(@value)
          end

          test "serialize_all returns all values in search format" do
            ProductTaxonomy::Value.stubs(:all_values_sorted).returns([@value])

            expected = [
              {
                "searchIdentifier" => "color__red",
                "title" => "Red [Color]",
                "url" => "?valueHandle=color__red",
                "value" => {
                  "handle" => "color__red",
                  "name" => "Red",
                  "attribute_handle" => "color",
                },
              },
            ]

            assert_equal expected, SearchSerializer.serialize_all
          end
        end
      end
    end
  end
end
