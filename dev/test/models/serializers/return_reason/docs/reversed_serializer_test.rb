# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        class ReversedSerializerTest < TestCase
          setup do
            @return_reason = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Test Return Reason",
              description: "Test Description",
              friendly_id: "test_return_reason",
              handle: "test_handle",
            )

            @category = ProductTaxonomy::Category.new(
              id: "te-1",
              name: "Test Category",
            )
            @category.return_reasons << @return_reason
          end

          test "serialize returns the expected JSON structure" do
            expected = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "handle" => "test_handle",
              "name" => "Test Return Reason",
              "description" => "Test Description",
              "categories" => [
                {
                  "id" => "gid://shopify/TaxonomyCategory/te-1",
                  "full_name" => "Test Category",
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize(@return_reason, [@category])
          end

          test "serialize with no categories returns empty array" do
            expected = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "handle" => "test_handle",
              "name" => "Test Return Reason",
              "description" => "Test Description",
              "categories" => [],
            }

            assert_equal expected, ReversedSerializer.serialize(@return_reason, [])
          end

          test "serialize with nil categories returns empty array" do
            expected = {
              "id" => "gid://shopify/ReturnReasonDefinition/1",
              "handle" => "test_handle",
              "name" => "Test Return Reason",
              "description" => "Test Description",
              "categories" => [],
            }

            assert_equal expected, ReversedSerializer.serialize(@return_reason, nil)
          end

          test "serialize_all returns all return reasons with their categories" do
            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])
            ProductTaxonomy::Category.stubs(:all).returns([@category])

            expected = {
              "return_reasons" => [
                {
                  "id" => "gid://shopify/ReturnReasonDefinition/1",
                  "handle" => "test_handle",
                  "name" => "Test Return Reason",
                  "description" => "Test Description",
                  "categories" => [
                    {
                      "id" => "gid://shopify/TaxonomyCategory/te-1",
                      "full_name" => "Test Category",
                    },
                  ],
                },
              ],
            }

            assert_equal expected, ReversedSerializer.serialize_all
          end

          test "serialize_all sorts categories by full_name" do
            category_b = ProductTaxonomy::Category.new(
              id: "te-2",
              name: "B Category",
            )
            category_a = ProductTaxonomy::Category.new(
              id: "te-3",
              name: "A Category",
            )

            # Add return reason to categories in reverse alphabetical order
            category_b.return_reasons << @return_reason
            category_a.return_reasons << @return_reason

            ProductTaxonomy::ReturnReason.stubs(:all).returns([@return_reason])
            ProductTaxonomy::Category.stubs(:all).returns([category_b, category_a])

            result = ReversedSerializer.serialize_all
            categories = result["return_reasons"][0]["categories"]

            assert_equal "A Category", categories[0]["full_name"]
            assert_equal "B Category", categories[1]["full_name"]
          end

          test "serialize_all preserves return reason source order" do
            return_reason_1 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "First",
              description: "First description",
              friendly_id: "first",
              handle: "first",
            )
            return_reason_2 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Second",
              description: "Second description",
              friendly_id: "second",
              handle: "second",
            )
            return_reason_3 = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Third",
              description: "Third description",
              friendly_id: "third",
              handle: "third",
            )

            ProductTaxonomy::ReturnReason.stubs(:all).returns([return_reason_2, return_reason_3, return_reason_1])
            ProductTaxonomy::Category.stubs(:all).returns([])

            result = ReversedSerializer.serialize_all
            handles = result["return_reasons"].map { |rr| rr["handle"] }

            assert_equal ["second", "third", "first"], handles
          end
        end
      end
    end
  end
end
