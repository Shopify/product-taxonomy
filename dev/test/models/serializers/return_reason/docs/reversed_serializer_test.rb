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

          test "serialize_all sorts return reasons with other last, unknown second-to-last" do
            unknown_return_reason = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Unknown",
              description: "Unknown reason",
              friendly_id: "unknown",
              handle: "unknown",
            )

            other_return_reason = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Other",
              description: "Other reason",
              friendly_id: "other",
              handle: "other",
            )

            normal_return_reason = ProductTaxonomy::ReturnReason.new(
              id: 4,
              name: "Normal Reason",
              description: "Normal description",
              friendly_id: "normal",
              handle: "normal",
            )

            # Return in non-sorted order
            ProductTaxonomy::ReturnReason.stubs(:all).returns([
              other_return_reason,
              normal_return_reason,
              unknown_return_reason,
            ])
            ProductTaxonomy::Category.stubs(:all).returns([])

            result = ReversedSerializer.serialize_all
            handles = result["return_reasons"].map { |rr| rr["handle"] }

            assert_equal ["normal", "unknown", "other"], handles
          end

          test "serialize_all sorts normal return reasons alphabetically by name" do
            return_reason_c = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Cccc",
              description: "Description C",
              friendly_id: "cccc",
              handle: "cccc",
            )

            return_reason_a = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Aaaa",
              description: "Description A",
              friendly_id: "aaaa",
              handle: "aaaa",
            )

            return_reason_b = ProductTaxonomy::ReturnReason.new(
              id: 3,
              name: "Bbbb",
              description: "Description B",
              friendly_id: "bbbb",
              handle: "bbbb",
            )

            # Add in non-alphabetical order
            ProductTaxonomy::ReturnReason.stubs(:all).returns([
              return_reason_c,
              return_reason_a,
              return_reason_b,
            ])
            ProductTaxonomy::Category.stubs(:all).returns([])

            result = ReversedSerializer.serialize_all
            handles = result["return_reasons"].map { |rr| rr["handle"] }

            assert_equal ["aaaa", "bbbb", "cccc"], handles
          end

          test "serialize_all uses ID as tiebreaker for identical names" do
            return_reason_1 = ProductTaxonomy::ReturnReason.new(
              id: 2,
              name: "Same Name",
              description: "Description 1",
              friendly_id: "same_name_1",
              handle: "same_name_1",
            )

            return_reason_2 = ProductTaxonomy::ReturnReason.new(
              id: 1,
              name: "Same Name",
              description: "Description 2",
              friendly_id: "same_name_2",
              handle: "same_name_2",
            )

            ProductTaxonomy::ReturnReason.stubs(:all).returns([return_reason_1, return_reason_2])
            ProductTaxonomy::Category.stubs(:all).returns([])

            result = ReversedSerializer.serialize_all
            handles = result["return_reasons"].map { |rr| rr["handle"] }

            # Should be sorted by ID (1, then 2) when names are identical
            assert_equal ["same_name_2", "same_name_1"], handles
          end
        end
      end
    end
  end
end
