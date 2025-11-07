# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Data
        class LocalizationsSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              friendly_id: "test_return_reason",
              handle: "test_handle",
              description: "The test description",
            )
          end

          test "serialize returns the expected data structure for a return reason" do
            expected = {
              "name" => "Test Return Reason",
              "description" => "The test description",
            }

            assert_equal expected, LocalizationsSerializer.serialize(@return_reason)
          end

          test "serialize_all returns all return reasons in localization format" do
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])

            expected = {
              "en" => {
                "return_reasons" => {
                  "test_return_reason" => {
                    "name" => "Test Return Reason",
                    "description" => "The test description",
                  },
                },
              },
            }

            assert_equal expected, LocalizationsSerializer.serialize_all
          end

          test "serialize_all sorts return reasons by friendly_id" do
            return_reason_c = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "C Return Reason",
              friendly_id: "c_return_reason",
              handle: "c_handle",
              description: "C Description",
            )

            return_reason_a = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "A Return Reason",
              friendly_id: "a_return_reason",
              handle: "a_handle",
              description: "A Description",
            )

            return_reason_b = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "B Return Reason",
              friendly_id: "b_return_reason",
              handle: "b_handle",
              description: "B Description",
            )

            # Return in non-alphabetical order
            ProductTaxonomy::ReturnReason.stubs(:all).returns([
              return_reason_c,
              return_reason_a,
              return_reason_b,
            ])

            result = LocalizationsSerializer.serialize_all
            friendly_ids = result["en"]["return_reasons"].keys

            # Should be sorted alphabetically by friendly_id
            assert_equal ["a_return_reason", "b_return_reason", "c_return_reason"], friendly_ids
          end
        end
      end
    end
  end
end
