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
                  },
                ],
              },
            }

            assert_equal expected, SiblingsSerializer.serialize_all
          end
        end
      end
    end
  end
end
