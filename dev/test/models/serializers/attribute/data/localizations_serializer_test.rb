# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
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
              description: "The color of the item",
              values: [@value]
            )
          end

          test "serialize returns the expected data structure for an attribute" do
            expected = {
              "color" => {
                "name" => "Color",
                "description" => "The color of the item"
              }
            }

            assert_equal expected, LocalizationsSerializer.serialize(@attribute)
          end

          test "serialize_all returns all attributes in localization format" do
            ProductTaxonomy::Attribute.stubs(:all).returns([@attribute])

            expected = {
              "en" => {
                "attributes" => {
                  "color" => {
                    "name" => "Color",
                    "description" => "The color of the item"
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
