# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        class FullNamesSerializerTest < TestCase
          setup do
            @root = ProductTaxonomy::Category.new(id: "aa", name: "Root")
            @child = ProductTaxonomy::Category.new(id: "aa-1", name: "Child")
            @grandchild = ProductTaxonomy::Category.new(id: "aa-1-1", name: "Grandchild")

            @root.add_child(@child)
            @child.add_child(@grandchild)
          end

          test "serialize returns the expected data structure" do
            expected = {
              "id" => "aa",
              "full_name" => "Root",
            }

            assert_equal expected, FullNamesSerializer.serialize(@root)
          end

          test "serialize generates proper full_name for child category" do
            expected = {
              "id" => "aa-1",
              "full_name" => "Root > Child",
            }

            assert_equal expected, FullNamesSerializer.serialize(@child)
          end

          test "serialize generates proper full_name for grandchild category" do
            expected = {
              "id" => "aa-1-1",
              "full_name" => "Root > Child > Grandchild",
            }

            assert_equal expected, FullNamesSerializer.serialize(@grandchild)
          end

          test "serialize_all returns all categories with correct full_names" do
            ProductTaxonomy::Category.add(@root)
            ProductTaxonomy::Category.add(@child)
            ProductTaxonomy::Category.add(@grandchild)

            expected = [
              {
                "id" => "aa",
                "full_name" => "Root",
              },
              {
                "id" => "aa-1",
                "full_name" => "Root > Child",
              },
              {
                "id" => "aa-1-1",
                "full_name" => "Root > Child > Grandchild",
              },
            ]

            assert_equal expected, FullNamesSerializer.serialize_all
          end

          test "serialize_all sorts categories by full_name" do
            cat_a = ProductTaxonomy::Category.new(id: "zz", name: "Apples")
            cat_b = ProductTaxonomy::Category.new(id: "yy", name: "Bananas")
            cat_c = ProductTaxonomy::Category.new(id: "xx", name: "Cherries")

            ProductTaxonomy::Category.add(cat_c)
            ProductTaxonomy::Category.add(cat_a)
            ProductTaxonomy::Category.add(cat_b)

            expected = [
              {
                "id" => "zz",
                "full_name" => "Apples",
              },
              {
                "id" => "yy",
                "full_name" => "Bananas",
              },
              {
                "id" => "xx",
                "full_name" => "Cherries",
              },
            ]

            assert_equal expected, FullNamesSerializer.serialize_all
          end
        end
      end
    end
  end
end
