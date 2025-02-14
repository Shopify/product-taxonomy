# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Data
        class LocalizationsSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "black",
              handle: "black"
            )

            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              friendly_id: "color",
              handle: "color",
              description: "Test attribute",
              values: [@value]
            )

            @value.stubs(:primary_attribute).returns(@attribute)
          end

          test "serialize returns the expected data structure for a value" do
            expected = {
              "black" => {
                "name" => "Black",
                "context" => "Color"
              }
            }

            assert_equal expected, LocalizationsSerializer.serialize(@value)
          end

          test "serialize_all returns all values in localization format" do
            ProductTaxonomy::Value.stubs(:all).returns([@value])

            expected = {
              "en" => {
                "values" => {
                  "black" => {
                    "name" => "Black",
                    "context" => "Color"
                  }
                }
              }
            }

            assert_equal expected, LocalizationsSerializer.serialize_all
          end
        end
      end
    end
  end
end
