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

          test "serialize writes `inherit` for categories that inherit their return reasons" do
            category = ProductTaxonomy::Category.new(id: "bb", name: "Inheriting Root", return_reasons: :inherit)

            assert_equal "inherit", DataSerializer.serialize(category)["return_reasons"]
          end

          test "serialize writes `inherit` even after inherited reasons have been resolved" do
            root = ProductTaxonomy::Category.new(
              id: "dd",
              name: "Defining Root",
              return_reasons: [return_reason(1, "color")],
            )
            child = ProductTaxonomy::Category.new(id: "dd-1", name: "Inheriting Child", return_reasons: :inherit)
            root.add_child(child)
            child.resolve_return_reasons

            assert_equal ["color"], child.return_reasons.map(&:friendly_id)
            assert_equal "inherit", DataSerializer.serialize(child)["return_reasons"]
          end

          test "serialize keeps the empty list of a category that fell back to the global reasons" do
            ProductTaxonomy::ReturnReason::GLOBAL_FRIENDLY_IDS.each_with_index do |friendly_id, index|
              ProductTaxonomy::ReturnReason.add(return_reason(index + 1, friendly_id))
            end
            ProductTaxonomy::Category.reset
            ProductTaxonomy::Category.load_from_source([
              { "id" => "ee", "name" => "Empty Root", "children" => [], "attributes" => [], "return_reasons" => [] },
            ])
            category = ProductTaxonomy::Category.find_by(id: "ee")

            # The resolved list is the global set, so runtime consumers get the baseline.
            assert_equal(
              ProductTaxonomy::ReturnReason::GLOBAL_FRIENDLY_IDS,
              category.return_reasons.map(&:friendly_id),
            )
            # But the data file keeps `[]`, otherwise dumping the taxonomy would freeze today's global reasons into
            # `data/categories/*.yml` and the category would stop picking up new ones.
            assert_empty category.defined_return_reasons
            assert_equal [], DataSerializer.serialize(category)["return_reasons"]
          end

          test "serialize writes out only the reasons a category defines after falling back to the global ones" do
            ProductTaxonomy::ReturnReason::GLOBAL_FRIENDLY_IDS.each_with_index do |friendly_id, index|
              ProductTaxonomy::ReturnReason.add(return_reason(index + 1, friendly_id))
            end
            category = ProductTaxonomy::Category.new(id: "ee", name: "Empty Root", return_reasons: [])
            category.resolve_return_reasons
            category.add_return_reason(return_reason(99, "too_big"))

            # The global reasons the category only resolved to are not written back as if it defined them.
            # `AddReturnReasonsToCategoriesCommand` is what appends them explicitly when it defines a list from
            # scratch, so the category does not silently lose them.
            assert_equal ["too_big"], category.defined_return_reasons.map(&:friendly_id)
            assert_equal ["too_big"], DataSerializer.serialize(category)["return_reasons"]
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
