# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  module Serializers
    module Attribute
      module Data
        class DataSerializerTest < TestCase
          setup do
            @value = ProductTaxonomy::Value.new(
              id: 1,
              name: "Black",
              friendly_id: "color__black",
              handle: "color__black",
            )

            @base_attribute = ProductTaxonomy::Attribute.new(
              id: 1,
              name: "Color",
              description: "Defines the primary color or pattern, such as blue or striped",
              friendly_id: "color",
              handle: "color",
              values: [@value],
            )

            @extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Clothing Color",
              description: "Color of the clothing",
              friendly_id: "clothing_color",
              handle: "clothing_color",
              values_from: @base_attribute
            )

            ProductTaxonomy::Value.add(@value)
            ProductTaxonomy::Attribute.add(@base_attribute)
            ProductTaxonomy::Attribute.add(@extended_attribute)
          end

          test "serialize returns the expected data structure for base attribute" do
            expected = {
              "id" => 1,
              "name" => "Color",
              "description" => "Defines the primary color or pattern, such as blue or striped",
              "friendly_id" => "color",
              "handle" => "color",
              "values" => ["color__black"]
            }

            assert_equal expected, DataSerializer.serialize(@base_attribute)
          end

          test "serialize returns the expected data structure for extended attribute" do
            expected = {
              "name" => "Clothing Color",
              "handle" => "clothing_color",
              "description" => "Color of the clothing",
              "friendly_id" => "clothing_color",
              "values_from" => "color"
            }

            assert_equal expected, DataSerializer.serialize(@extended_attribute)
          end

          test "serialize_all returns all attributes in data format" do
            expected = {
              "base_attributes" => [{
                "id" => 1,
                "name" => "Color",
                "description" => "Defines the primary color or pattern, such as blue or striped",
                "friendly_id" => "color",
                "handle" => "color",
                "values" => ["color__black"]
              }],
              "extended_attributes" => [{
                "name" => "Clothing Color",
                "handle" => "clothing_color",
                "description" => "Color of the clothing",
                "friendly_id" => "clothing_color",
                "values_from" => "color"
              }]
            }

            assert_equal expected, DataSerializer.serialize_all
          end

          test "serialize includes sorting field when attribute is manually sorted" do
            @base_attribute = ProductTaxonomy::Attribute.new(
              id: 2,
              name: "Size",
              description: "Defines the size of the product",
              friendly_id: "size",
              handle: "size",
              values: [@value],
              is_manually_sorted: true
            )
            ProductTaxonomy::Attribute.add(@base_attribute)

            expected = {
              "id" => 2,
              "name" => "Size",
              "description" => "Defines the size of the product",
              "friendly_id" => "size",
              "handle" => "size",
              "sorting" => "custom",
              "values" => ["color__black"]
            }

            assert_equal expected, DataSerializer.serialize(@base_attribute)
          end

          test "serialize_all sorts base attributes by ID" do
            second_base_attribute = ProductTaxonomy::Attribute.new(
              id: 2,
              name: "Size",
              description: "Defines the size of the product",
              friendly_id: "size",
              handle: "size",
              values: []
            )
            third_base_attribute = ProductTaxonomy::Attribute.new(
              id: 3,
              name: "Material",
              description: "Defines the material of the product",
              friendly_id: "material",
              handle: "material",
              values: []
            )
            # Add attributes in random order to ensure sorting is by ID
            ProductTaxonomy::Attribute.add(third_base_attribute)
            ProductTaxonomy::Attribute.add(second_base_attribute)

            result = DataSerializer.serialize_all
            base_attributes = result["base_attributes"]

            assert_equal 3, base_attributes.length
            assert_equal "color", base_attributes[0]["friendly_id"]
            assert_equal "size", base_attributes[1]["friendly_id"]
            assert_equal "material", base_attributes[2]["friendly_id"]
          end

          test "serialize_all preserves extended attributes order" do
            second_extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Shoe Color",
              description: "Color of the shoe",
              friendly_id: "shoe_color",
              handle: "shoe_color",
              values_from: @base_attribute
            )
            third_extended_attribute = ProductTaxonomy::ExtendedAttribute.new(
              name: "Accessory Color",
              description: "Color of the accessory",
              friendly_id: "accessory_color",
              handle: "accessory_color",
              values_from: @base_attribute
            )
            # Add extended attributes in specific order
            ProductTaxonomy::Attribute.add(second_extended_attribute)
            ProductTaxonomy::Attribute.add(third_extended_attribute)

            result = DataSerializer.serialize_all
            extended_attributes = result["extended_attributes"]

            assert_equal 3, extended_attributes.length
            assert_equal "clothing_color", extended_attributes[0]["friendly_id"]
            assert_equal "shoe_color", extended_attributes[1]["friendly_id"]
            assert_equal "accessory_color", extended_attributes[2]["friendly_id"]
          end
        end
      end
    end
  end
end
