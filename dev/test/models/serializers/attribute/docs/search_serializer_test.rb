# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        class SearchSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Test Value",
              friendly_id: "test_value",
              handle: "test_value",
            )

            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Test Attribute",
              description: "Test Description",
              friendly_id: "test_attribute",
              handle: "test_handle",
              values: [@value],
            )
          end

          test "serialize returns the expected search structure" do
            expected = {
              "searchIdentifier" => "test_handle",
              "title" => "Test Attribute",
              "url" => "?attributeHandle=test_handle",
              "attribute" => {
                "handle" => "test_handle",
              },
            }

            assert_equal expected, SearchSerializer.serialize(@attribute)
          end

          test "serialize_all returns all attributes in search format" do
            ProductTaxonomy::Attribute.stubs(:all).returns([@attribute])

            expected = [
              {
                "searchIdentifier" => "test_handle",
                "title" => "Test Attribute",
                "url" => "?attributeHandle=test_handle",
                "attribute" => {
                  "handle" => "test_handle",
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
