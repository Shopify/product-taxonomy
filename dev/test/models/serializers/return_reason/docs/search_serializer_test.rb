# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        class SearchSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )
          end

          test "serialize returns the expected search structure" do
            expected = {
              "searchIdentifier" => "test_handle",
              "title" => "Test Return Reason",
              "url" => "?returnReasonHandle=test_handle",
              "return_reason" => {
                "handle" => "test_handle",
                "name" => "Test Return Reason",
                "description" => "Test Description",
              },
            }

            assert_equal expected, SearchSerializer.serialize(@return_reason)
          end

          test "serialize URL encodes the handle with special characters" do
            return_reason_with_special_chars = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Test Reason",
              description: "Test",
              friendly_id: "test_reason",
              handle: "test reason+special",
            )

            result = SearchSerializer.serialize(return_reason_with_special_chars)

            assert_equal "?returnReasonHandle=test%20reason%2Bspecial", result["url"]
          end

          test "serialize URL encodes handles with ampersands" do
            return_reason = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Test & Reason",
              description: "Test",
              friendly_id: "test_and_reason",
              handle: "test&reason",
            )

            result = SearchSerializer.serialize(return_reason)

            assert_equal "?returnReasonHandle=test%26reason", result["url"]
          end

          test "serialize_all returns all return reasons in search format" do
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])

            expected = [
              {
                "searchIdentifier" => "test_handle",
                "title" => "Test Return Reason",
                "url" => "?returnReasonHandle=test_handle",
                "return_reason" => {
                  "handle" => "test_handle",
                  "name" => "Test Return Reason",
                  "description" => "Test Description",
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
