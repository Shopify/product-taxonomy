# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        class LocalizationsSerializerTest < TestCase
          setup do
            @root = ProductTaxonomy::Category.new(id: "aa", name: "Root")
            @child = ProductTaxonomy::Category.new(id: "aa-1", name: "Child")
            @root.add_child(@child)

            ProductTaxonomy::Category.add(@root)
            ProductTaxonomy::Category.add(@child)
            ProductTaxonomy::Category.stubs(:verticals).returns([@root])
          end

          teardown do
            ProductTaxonomy::Category.reset
          end

          test "serialize returns the expected data structure for a category" do
            expected = {
              "aa" => {
                "name" => "Root",
                "context" => "Root",
              }
            }

            assert_equal expected, LocalizationsSerializer.serialize(@root)
          end

          test "serialize_all returns all categories in localization format" do
            expected = {
              "en" => {
                "categories" => {
                  "aa" => {
                    "name" => "Root",
                    "context" => "Root",
                  },
                  "aa-1" => {
                    "name" => "Child",
                    "context" => "Root > Child",
                  }
                }
              }
            }

            assert_equal expected, LocalizationsSerializer.serialize_all
          end
        end
      end
    end
  end
end
