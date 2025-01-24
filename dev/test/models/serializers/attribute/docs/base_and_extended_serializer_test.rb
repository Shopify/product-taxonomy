# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        class BaseAndExtendedSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Test Value",
              friendly_id: "test_value",
              handle: "test_value",
            )

            @base_attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Base Attribute",
              description: "Base Description",
              friendly_id: "base_attribute",
              handle: "base_handle",
              values: [@value],
            )

            @extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Extended Attribute",
              description: "Extended Description",
              friendly_id: "extended_attribute",
              handle: "extended_handle",
              values_from: @base_attribute,
            )
          end

          test "serialize base attribute returns the expected structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "name" => "Base Attribute",
              "handle" => "base_handle",
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Test Value",
                },
              ],
            }

            assert_equal expected, BaseAndExtendedSerializer.serialize(@base_attribute)
          end

          test "serialize extended attribute returns the expected structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "name" => "Base Attribute",
              "handle" => "extended_handle",
              "extended_name" => "Extended Attribute",
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Test Value",
                },
              ],
            }

            assert_equal expected, BaseAndExtendedSerializer.serialize(@extended_attribute)
          end

          test "serialize_all returns base and extended attributes in correct order" do
            ProductTaxonomy::Attribute.stubs(:sorted_base_attributes).returns([@base_attribute])
            @base_attribute.stubs(:extended_attributes).returns([@extended_attribute])

            expected = [
              {
                "id" => "gid://shopify/TaxonomyAttribute/1",
                "name" => "Base Attribute",
                "handle" => "extended_handle",
                "extended_name" => "Extended Attribute",
                "values" => [
                  {
                    "id" => "gid://shopify/TaxonomyValue/1",
                    "name" => "Test Value",
                  },
                ],
              },
              {
                "id" => "gid://shopify/TaxonomyAttribute/1",
                "name" => "Base Attribute",
                "handle" => "base_handle",
                "values" => [
                  {
                    "id" => "gid://shopify/TaxonomyValue/1",
                    "name" => "Test Value",
                  },
                ],
              },
            ]

            assert_equal expected, BaseAndExtendedSerializer.serialize_all
          end
        end
      end
    end
  end
end
