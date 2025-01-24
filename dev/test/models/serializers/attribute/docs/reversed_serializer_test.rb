# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        class ReversedSerializerTest < TestCase
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

            @category = ProductTaxonomy::Category.new(
              id: 1,
              name: "Test Category",
            )
            @category.attributes << @attribute
          end

          test "serialize returns the expected JSON structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyAttribute/1",
              "handle" => "test_handle",
              "name" => "Test Attribute",
              "base_name" => nil,
              "categories" => [
                {
                  "id" => "gid://shopify/TaxonomyCategory/1",
                  "full_name" => "Test Category",
                },
              ],
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Test Value",
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize(@attribute, [@category])
          end

          test "serialize with extended attribute returns the expected JSON structure" do
            base_attribute = ProductTaxonomy::Attribute.new(
              id: 2,
              name: "Base Attribute",
              description: "Base Description",
              friendly_id: "base_attribute",
              handle: "base_handle",
              values: [@value],
            )
            extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Extended Attribute",
              description: "Extended Description",
              friendly_id: "extended_attribute",
              handle: "extended_handle",
              values_from: base_attribute,
            )

            expected = {
              "id" => "gid://shopify/TaxonomyAttribute/2",
              "handle" => "extended_handle",
              "name" => "Extended Attribute",
              "base_name" => "Base Attribute",
              "categories" => [],
              "values" => [
                {
                  "id" => "gid://shopify/TaxonomyValue/1",
                  "name" => "Test Value",
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize(extended_attribute, [])
          end

          test "serialize_all returns all attributes with their categories" do
            ProductTaxonomy::Attribute.stubs(:all).returns([@attribute])
            ProductTaxonomy::Category.stubs(:all).returns([@category])

            expected = {
              "attributes" => [
                {
                  "id" => "gid://shopify/TaxonomyAttribute/1",
                  "handle" => "test_handle",
                  "name" => "Test Attribute",
                  "base_name" => nil,
                  "categories" => [
                    {
                      "id" => "gid://shopify/TaxonomyCategory/1",
                      "full_name" => "Test Category",
                    },
                  ],
                  "values" => [
                    {
                      "id" => "gid://shopify/TaxonomyValue/1",
                      "name" => "Test Value",
                    },
                  ],
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize_all
          end
        end
      end
    end
  end
end
