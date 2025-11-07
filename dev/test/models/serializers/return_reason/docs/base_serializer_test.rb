# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        class BaseSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )
          end

          test "serialize returns the expected structure" do
            expected = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "name" => "Test Return Reason",
              "handle" => "test_handle",
              "description" => "Test Description",
            }

            assert_equal expected, BaseSerializer.serialize(@return_reason)
          end

          test "serialize_all returns all return reasons" do
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])

            expected = [
              {
                "id" => "gid://shopify/ReturnReasonDefinition/1",
                "name" => "Test Return Reason",
                "handle" => "test_handle",
                "description" => "Test Description",
              },
            ]

            assert_equal expected, BaseSerializer.serialize_all
          end
        end
      end
    end
  end
end
