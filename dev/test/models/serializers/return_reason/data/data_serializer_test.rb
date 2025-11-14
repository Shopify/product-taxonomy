# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        class DataSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )

            ProductTaxonomy::ReturnReason.add(@return_reason)
          end

          test "serialize returns the expected data structure" do
            expected = {
              "id" => 1,
              "name" => "Test Return Reason",
              "description" => "Test Description",
              "friendly_id" => "test_return_reason",
              "handle" => "test_handle",
            }

            assert_equal expected, DataSerializer.serialize(@return_reason)
          end

          test "serialize_all returns all return reasons in data format" do
            expected = [
              {
                "id" => 1,
                "name" => "Test Return Reason",
                "description" => "Test Description",
                "friendly_id" => "test_return_reason",
                "handle" => "test_handle",
              },
            ]

            assert_equal expected, DataSerializer.serialize_all
          end

          test "serialize_all sorts return reasons by ID" do
            return_reason_3 = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Third Return Reason",
              description: "Third Description",
              friendly_id: "third_return_reason",
              handle: "third_handle",
            )

            return_reason_2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Second Return Reason",
              description: "Second Description",
              friendly_id: "second_return_reason",
              handle: "second_handle",
            )

            # Add in non-sorted order to ensure sorting by ID
            ProductTaxonomy::ReturnReason.add(return_reason_3)
            ProductTaxonomy::ReturnReason.add(return_reason_2)

            result = DataSerializer.serialize_all
            ids = result.map { |rr| rr["id"] }

            assert_equal [1, 2, 3], ids
          end
        end
      end
    end
  end
end
