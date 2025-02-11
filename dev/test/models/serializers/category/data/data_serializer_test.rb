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
            }

            assert_equal expected, DataSerializer.serialize(@root)
          end

          test "serialize_all returns all categories in data format" do
            expected = [
              {
                "id" => "aa",
                "name" => "Root",
                "children" => ["aa-1"],
                "attributes" => [],
              },
              {
                "id" => "aa-1",
                "name" => "Child",
                "children" => [],
                "attributes" => ["color"],
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
              },
              {
                "id" => "aa-1",
                "name" => "Child",
                "children" => [],
                "attributes" => ["color"],
              },
            ]

            assert_equal expected, DataSerializer.serialize_all(@root)
          end
        end
      end
    end
  end
end
