# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        class DataSerializerTest < TestCase
          setup do
            @root = ProductTaxonomy::Category.new(id: "aa", name: "Root")
            @child = ProductTaxonomy::Category.new(id: "aa-1", name: "Child")
            @root.add_child(@child)

            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "black",
              handle: "black",
            )

            @attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              friendly_id: "color",
              handle: "color",
              description: "Test attribute",
              values: [@value],
            )
            @child.attributes << @attribute

            ProductTaxonomy::Category.add(@root)
            ProductTaxonomy::Category.add(@child)
            ProductTaxonomy::Category.stubs(:verticals).returns([@root])
          end

          teardown do
            ProductTaxonomy::Category.reset
          end

          test "serialize returns the expected data structure" do
            expected = {
              "id" => "aa",
              "name" => "Root",
              "children" => ["aa-1"],
              "attributes" => [],
              "return_reasons" => [],
            }

            assert_equal expected, DataSerializer.serialize(@root)
          end

          test "serialize preserves the return reason order, moving unknown and other_reason to the end" do
            category = ProductTaxonomy::Category.new(
              id: "cc",
              name: "Sorted Root",
              return_reasons: [
                return_reason(1, "too_big"),
                return_reason(2, "other_reason"),
                return_reason(3, "changed_my_mind"),
                return_reason(4, "unknown"),
                return_reason(5, "color"),
              ],
            )

            expected = ["too_big", "changed_my_mind", "color", "unknown", "other_reason"]

            assert_equal expected, DataSerializer.serialize(category)["return_reasons"]
          end

          test "serialize_all returns all categories in data format" do
            expected = [
              {
                "id" => "aa",
                "name" => "Root",
                "children" => ["aa-1"],
                "attributes" => [],
                "return_reasons" => [],
              },
              {
                "id" => "aa-1",
                "name" => "Child",
                "children" => [],
                "attributes" => ["color"],
                "return_reasons" => [],
              },
            ]

            assert_equal expected, DataSerializer.serialize_all
          end

          test "serialize_all with root returns descendants and self in data format" do
            expected = [
              {
                "id" => "aa",
                "name" => "Root",
                "children" => ["aa-1"],
                "attributes" => [],
                "return_reasons" => [],
              },
              {
                "id" => "aa-1",
                "name" => "Child",
                "children" => [],
                "attributes" => ["color"],
                "return_reasons" => [],
              },
            ]

            assert_equal expected, DataSerializer.serialize_all(@root)
          end

          private

          def return_reason(id, friendly_id)
            ProductTaxonomy::ReturnReason.new(
              id:,
              name: friendly_id.tr("_", " ").capitalize,
              description: "Description for #{friendly_id}",
              friendly_id:,
              handle: friendly_id.tr("_", "-"),
            )
          end
        end
      end
    end
  end
end
