# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Docs
        class SiblingsSerializerTest < TestCase
          setup do
            @parent = ProductTaxonomy::Category.new(
              id: 1,
              name: "Parent Category",
            )

            @category = ProductTaxonomy::Category.new(
              id: 2,
              name: "Test Category",
              parent: @parent,
            )

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
            @category.attributes << @attribute
          end

          test "serialize returns the expected structure" do
            expected = {
              "id" => "gid://shopify/TaxonomyCategory/2",
              "name" => "Test Category",
              "fully_qualified_type" => "Parent Category > Test Category",
              "depth" => 1,
              "parent_id" => "gid://shopify/TaxonomyCategory/1",
              "node_type" => "leaf",
              "ancestor_ids" => "gid://shopify/TaxonomyCategory/1",
              "attribute_handles" => "test_handle",
              "return_reason_handles" => "",
            }

            assert_equal expected, SiblingsSerializer.serialize(@category)
          end

          test "serialize root category returns the expected structure" do
            root_category = ProductTaxonomy::Category.new(
              id: 3,
              name: "Root Category",
            )

            expected = {
              "id" => "gid://shopify/TaxonomyCategory/3",
              "name" => "Root Category",
              "fully_qualified_type" => "Root Category",
              "depth" => 0,
              "parent_id" => "root",
              "node_type" => "root",
              "ancestor_ids" => "",
              "attribute_handles" => "",
              "return_reason_handles" => "",
            }

            assert_equal expected, SiblingsSerializer.serialize(root_category)
          end

          test "serialize_all returns categories grouped by level and parent" do
            ProductTaxonomy::Category.stubs(:all_depth_first).returns([@parent, @category])

            expected = {
              0 => {
                "root" => [
                  {
                    "id" => "gid://shopify/TaxonomyCategory/1",
                    "name" => "Parent Category",
                    "fully_qualified_type" => "Parent Category",
                    "depth" => 0,
                    "parent_id" => "root",
                    "node_type" => "root",
                    "ancestor_ids" => "",
                    "attribute_handles" => "",
                    "return_reason_handles" => "",
                  },
                ],
              },
              1 => {
                "gid://shopify/TaxonomyCategory/1" => [
                  {
                    "id" => "gid://shopify/TaxonomyCategory/2",
                    "name" => "Test Category",
                    "fully_qualified_type" => "Parent Category > Test Category",
                    "depth" => 1,
                    "parent_id" => "gid://shopify/TaxonomyCategory/1",
                    "node_type" => "leaf",
                    "ancestor_ids" => "gid://shopify/TaxonomyCategory/1",
                    "attribute_handles" => "test_handle",
                    "return_reason_handles" => "",
                  },
                ],
              },
            }

            assert_equal expected, SiblingsSerializer.serialize_all
          end

          test "serialize category with return reasons returns expected structure" do
            return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_return_reason_handle",
            )

            category = ProductTaxonomy::Category.new(
              id: "te-1",
              name: "Test Category",
              return_reasons: [return_reason],
            )

            expected = {
              "id" => "gid://shopify/TaxonomyCategory/te-1",
              "name" => "Test Category",
              "fully_qualified_type" => "Test Category",
              "depth" => 0,
              "parent_id" => "root",
              "node_type" => "root",
              "ancestor_ids" => "",
              "attribute_handles" => "",
              "return_reason_handles" => "test_return_reason_handle",
            }

            assert_equal expected, SiblingsSerializer.serialize(category)
          end

          test "serialize category with multiple return reasons returns comma-separated handles" do
            return_reason1 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Return Reason One",
              description: "First return reason",
              friendly_id: "return_reason_one",
              handle: "return_reason_one",
            )

            return_reason2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Return Reason Two",
              description: "Second return reason",
              friendly_id: "return_reason_two",
              handle: "return_reason_two",
            )

            category = ProductTaxonomy::Category.new(
              id: "te-1",
              name: "Test Category",
              return_reasons: [return_reason1, return_reason2],
            )

            expected = {
              "id" => "gid://shopify/TaxonomyCategory/te-1",
              "name" => "Test Category",
              "fully_qualified_type" => "Test Category",
              "depth" => 0,
              "parent_id" => "root",
              "node_type" => "root",
              "ancestor_ids" => "",
              "attribute_handles" => "",
              "return_reason_handles" => "return_reason_one,return_reason_two",
            }

            assert_equal expected, SiblingsSerializer.serialize(category)
          end
        end
      end
    end
  end
end
