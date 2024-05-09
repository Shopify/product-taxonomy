# frozen_string_literal: true

require_relative "../test_helper"

class PropertyTest < ApplicationTestCase
  def teardown
    Property.delete_all
    PropertyValue.delete_all
  end

  test "default ordering is alphabetical" do
    material = create(:property, name: "Material")
    size = create(:property, name: "size")
    color = create(:property, name: "Color")

    assert_equal [color, material, size], Property.all.to_a
  end

  test ".base returns base properties" do
    base_property.save!
    extended_property.save!

    assert_equal [base_property], Property.base
  end

  test ".extended returns properties based off others" do
    base_property.save!
    extended_property.save!

    assert_equal [extended_property], Property.extended
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyAttribute/42", build(:property, id: 42).gid
  end

  test "#gid returns base_property.gid when extended" do
    refute_equal base_property.id, extended_property.id
    assert_equal base_property.gid, extended_property.gid
  end

  test "#base?" do
    assert_predicate base_property, :base?
    refute_predicate extended_property, :base?
  end

  test "#extended?" do
    refute_predicate base_property, :extended?
    assert_predicate extended_property, :extended?
  end

  test "#friendly_id must be unique" do
    create(:property, friendly_id: "material")
    another_material = build(:property, friendly_id: "material")

    refute_predicate another_material, :valid?
  end

  test "#property_values must match base_property#property_values" do
    value = build(:property_value)
    base_property.property_values = [value]
    extended_property.property_values = [value]

    assert_predicate base_property, :valid?
    assert_predicate extended_property, :valid?

    extended_property.property_values = []

    refute_predicate extended_property, :valid?
  end

  test ".new_from_data creates a new property" do
    base_property = Property.new_from_data(
      "id" => 1,
      "name" => "Color",
      "friendly_id" => "color",
      "handle" => "color",
    )

    assert_equal 1, base_property.id
    assert_equal "Color", base_property.name
    assert_equal "color", base_property.friendly_id
    assert_equal "color", base_property.handle
    assert_nil base_property.base_friendly_id

    extended_property = Property.new_from_data(
      "name" => "Swatch Color",
      "friendly_id" => "swatch_color",
      "handle" => "swatch-color",
      "values_from" => "color",
    )

    assert_nil extended_property.id
    assert_equal "Swatch Color", extended_property.name
    assert_equal "swatch_color", extended_property.friendly_id
    assert_equal "swatch-color", extended_property.handle
    assert_equal "color", extended_property.base_friendly_id
  end

  test ".insert_all_from_data creates multiple categories" do
    data = [
      { "id" => 1, "name" => "Color", "friendly_id" => "color", "handle" => "color" },
      { "id" => 2, "name" => "Size", "friendly_id" => "size", "handle" => "size" },
    ]

    assert_difference -> { Property.count }, 2 do
      Property.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    red = build(:property_value, name: "Red")
    color = create(:property, name: "Color", property_values: [red])
    create(:property, name: "Swatch Color", handle: "swatch-color", base_property: color, property_values: [red])

    color.reload

    assert_equal(
      {
        "version" => 1,
        "attributes" => [
          {
            "id" => "gid://shopify/TaxonomyAttribute/#{color.id}",
            "name" => "Color",
            "handle" => "color",
            "extended_attributes" => [
              {
                "name" => "Swatch Color",
                "handle" => "swatch-color",
              },
            ],
            "values" => [
              {
                "id" => "gid://shopify/TaxonomyValue/#{red.id}",
                "name" => "Red",
                "handle" => "red",
              },
            ],
          },
        ],
      },
      Property.as_json([color], version: 1),
    )
  end

  test ".as_txt returns padded and version string representation" do
    color = create(:property, name: "Color")
    size = create(:property, name: "Size")

    assert_equal <<~TXT.strip, Property.as_txt([color, size], version: 1)
      # Shopify Product Taxonomy - Attributes: 1
      # Format: {GID} : {Attribute name}

      gid://shopify/TaxonomyAttribute/#{color.id} : Color
      gid://shopify/TaxonomyAttribute/#{size.id} : Size
    TXT
  end

  test "#as_json_for_data returns data json" do
    red = build(:property_value, name: "Red")
    color = create(:property, name: "Color", property_values: [red])

    assert_equal(
      {
        "id" => color.id,
        "name" => "Color",
        "handle" => "color",
        "friendly_id" => "color",
        "values" => [red.friendly_id],
      },
      color.as_json_for_data,
    )

    swatch_color = create(
      :property,
      name: "Swatch Color",
      handle: "swatch-color",
      base_property: color,
      property_values: [red],
    )

    assert_equal(
      {
        "name" => "Swatch Color",
        "handle" => "swatch-color",
        "friendly_id" => "swatch-color",
        "values_from" => "color",
      },
      swatch_color.as_json_for_data,
    )
  end

  private

  def base_property
    @base_property ||= build(:property)
  end

  def extended_property
    @extended_property ||= build(:property, base_property:)
  end
end
