# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Docs
        class SearchSerializerTest < TestCase
          setup do
            @category = ProductTaxonomy::Category.new(
              id: 1,
              name: "Test Category",
            )
          end

          test "serialize returns the expected search structure" do
            expected = {
              "searchIdentifier" => "gid://shopify/TaxonomyCategory/1",
              "title" => "Test Category",
              "url" => "?categoryId=gid%3A%2F%2Fshopify%2FTaxonomyCategory%2F1",
              "category" => {
                "id" => "gid://shopify/TaxonomyCategory/1",
                "name" => "Test Category",
                "fully_qualified_type" => "Test Category",
                "depth" => 0,
              },
            }

            assert_equal expected, SearchSerializer.serialize(@category)
          end

          test "serialize_all returns all categories in search format" do
            ProductTaxonomy::Category.stubs(:all_depth_first).returns([@category])

            expected = [
              {
                "searchIdentifier" => "gid://shopify/TaxonomyCategory/1",
                "title" => "Test Category",
                "url" => "?categoryId=gid%3A%2F%2Fshopify%2FTaxonomyCategory%2F1",
                "category" => {
                  "id" => "gid://shopify/TaxonomyCategory/1",
                  "name" => "Test Category",
                  "fully_qualified_type" => "Test Category",
                  "depth" => 0,
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
