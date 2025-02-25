# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Value
      module Data
        class DataSerializerTest < TestCase
          setup do
            @value1 = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "color__black",
              handle: "color__black"
            )
            @value2 = ProductTaxonomy::Value.new(
              id: 2,
              name: "Red",
              friendly_id: "color__red",
              handle: "color__red"
            )
            @value3 = ProductTaxonomy::Value.new(
              id: 3,
              name: "Blue",
              friendly_id: "color__blue",
              handle: "color__blue"
            )

            ProductTaxonomy::Value.add(@value1)
            ProductTaxonomy::Value.add(@value2)
            ProductTaxonomy::Value.add(@value3)
          end

          test "serialize returns the expected data structure for a value" do
            expected = {
              "id" => 1,
              "name" => "Black",
              "friendly_id" => "color__black",
              "handle" => "color__black"
            }

            assert_equal expected, DataSerializer.serialize(@value1)
          end

          test "serialize_all returns all values in data format" do
            expected = [
              {
                "id" => 1,
                "name" => "Black",
                "friendly_id" => "color__black",
                "handle" => "color__black"
              },
              {
                "id" => 2,
                "name" => "Red",
                "friendly_id" => "color__red",
                "handle" => "color__red"
              },
              {
                "id" => 3,
                "name" => "Blue",
                "friendly_id" => "color__blue",
                "handle" => "color__blue"
              }
            ]

            assert_equal expected, DataSerializer.serialize_all
          end

          test "serialize_all sorts values by ID" do
            # Add values in random order to ensure sorting is by ID
            ProductTaxonomy::Value.reset
            ProductTaxonomy::Value.add(@value3)
            ProductTaxonomy::Value.add(@value1)
            ProductTaxonomy::Value.add(@value2)

            result = DataSerializer.serialize_all

            assert_equal 3, result.length
            assert_equal "color__black", result[0]["friendly_id"]
            assert_equal "color__red", result[1]["friendly_id"]
            assert_equal "color__blue", result[2]["friendly_id"]
          end
        end
      end
    end
  end
end
