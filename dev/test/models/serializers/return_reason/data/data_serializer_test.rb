# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        class DataSerializerTest < TestCase
          setup do
            @return_reason1 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Damaged",
              description: "Item was damaged",
              friendly_id: "damaged",
              handle: "damaged",
            )
            @return_reason2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Wrong Item",
              description: "Wrong item received",
              friendly_id: "wrong_item",
              handle: "wrong_item",
            )
            @return_reason3 = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Not as Described",
              description: "Item not as described",
              friendly_id: "not_as_described",
              handle: "not_as_described",
            )

            ProductTaxonomy::ReturnReason.add(@return_reason1)
            ProductTaxonomy::ReturnReason.add(@return_reason2)
            ProductTaxonomy::ReturnReason.add(@return_reason3)
          end

          test "serialize returns the expected data structure for a return reason" do
            expected = {
              "id" => 1,
              "name" => "Damaged",
              "description" => "Item was damaged",
              "friendly_id" => "damaged",
              "handle" => "damaged",
            }

            assert_equal expected, DataSerializer.serialize(@return_reason1)
          end

          test "serialize_all returns all return reasons in data format" do
            expected = [
              {
                "id" => 1,
                "name" => "Damaged",
                "description" => "Item was damaged",
                "friendly_id" => "damaged",
                "handle" => "damaged",
              },
              {
                "id" => 2,
                "name" => "Wrong Item",
                "description" => "Wrong item received",
                "friendly_id" => "wrong_item",
                "handle" => "wrong_item",
              },
              {
                "id" => 3,
                "name" => "Not as Described",
                "description" => "Item not as described",
                "friendly_id" => "not_as_described",
                "handle" => "not_as_described",
              },
            ]

            assert_equal expected, DataSerializer.serialize_all
          end

          test "serialize_all sorts return reasons by ID" do
            # Add return reasons in random order to ensure sorting is by ID
            ProductTaxonomy::ReturnReason.reset
            ProductTaxonomy::ReturnReason.add(@return_reason3)
            ProductTaxonomy::ReturnReason.add(@return_reason1)
            ProductTaxonomy::ReturnReason.add(@return_reason2)

            result = DataSerializer.serialize_all

            assert_equal 3, result.length
            assert_equal "damaged", result[0]["friendly_id"]
            assert_equal "wrong_item", result[1]["friendly_id"]
            assert_equal "not_as_described", result[2]["friendly_id"]
          end
        end
      end
    end
  end
end
