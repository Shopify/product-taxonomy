# frozen_string_literal: true

require_relative "../test_helper"

class AttributeTest < ApplicationTestCase
  def teardown
    Attribute.delete_all
    Value.delete_all
  end

  test "default ordering is alphabetical" do
    material = create(:attribute, name: "Material")
    size = create(:attribute, name: "size")
    color = create(:attribute, name: "Color")

    assert_equal [color, material, size], Attribute.all.to_a
  end

  test ".base returns base attributes" do
    base_attribute.save!
    extended_attribute.save!

    assert_equal [base_attribute], Attribute.base
  end

  test ".extended returns attributes based off others" do
    base_attribute.save!
    extended_attribute.save!

    assert_equal [extended_attribute], Attribute.extended
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyAttribute/42", build(:attribute, id: 42).gid
  end

  test "#gid returns base_attribute.gid when extended" do
    refute_equal base_attribute.id, extended_attribute.id
    assert_equal base_attribute.gid, extended_attribute.gid
  end

  test "#base?" do
    assert_predicate base_attribute, :base?
    refute_predicate extended_attribute, :base?
  end

  test "#extended?" do
    refute_predicate base_attribute, :extended?
    assert_predicate extended_attribute, :extended?
  end

  test "#friendly_id must be unique" do
    create(:attribute, friendly_id: "material")
    another_material = build(:attribute, friendly_id: "material")

    refute_predicate another_material, :valid?
  end

  test "#values must match base_attribute#values" do
    value = build(:value)
    base_attribute.values = [value]
    extended_attribute.values = [value]

    assert_predicate base_attribute, :valid?
    assert_predicate extended_attribute, :valid?

    extended_attribute.values = []

    refute_predicate extended_attribute, :valid?
  end

  test ".new_from_data creates a new attribute" do
    base_attribute = Attribute.new_from_data(
      "id" => 1,
      "name" => "Color",
      "friendly_id" => "color",
      "handle" => "color",
    )

    assert_equal 1, base_attribute.id
    assert_equal "Color", base_attribute.name
    assert_equal "color", base_attribute.friendly_id
    assert_equal "color", base_attribute.handle
    assert_nil base_attribute.base_friendly_id

    extended_attribute = Attribute.new_from_data(
      "name" => "Swatch Color",
      "friendly_id" => "swatch_color",
      "handle" => "swatch-color",
      "values_from" => "color",
    )

    assert_nil extended_attribute.id
    assert_equal "Swatch Color", extended_attribute.name
    assert_equal "swatch_color", extended_attribute.friendly_id
    assert_equal "swatch-color", extended_attribute.handle
    assert_equal "color", extended_attribute.base_friendly_id
  end

  test ".insert_all_from_data creates multiple categories" do
    data = [
      { "id" => 1, "name" => "Color", "friendly_id" => "color", "handle" => "color" },
      { "id" => 2, "name" => "Size", "friendly_id" => "size", "handle" => "size" },
    ]

    assert_difference -> { Attribute.count }, 2 do
      Attribute.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    red = build(:value, name: "Red")
    color = create(:attribute, name: "Color", values: [red])
    create(:attribute, name: "Swatch Color", handle: "swatch-color", base_attribute: color, values: [red])

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
      Attribute.as_json([color], version: 1),
    )
  end

  test ".as_txt returns padded and version string representation" do
    color = create(:attribute, name: "Color")
    size = create(:attribute, name: "Size")

    assert_equal <<~TXT.strip, Attribute.as_txt([color, size], version: 1)
      # Shopify Product Taxonomy - Attributes: 1
      # Format: {GID} : {Attribute name}

      gid://shopify/TaxonomyAttribute/#{color.id} : Color
      gid://shopify/TaxonomyAttribute/#{size.id} : Size
    TXT
  end

  test "#as_json_for_data returns data json" do
    red = build(:value, name: "Red")
    color = create(:attribute, name: "Color", values: [red])

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
      :attribute,
      name: "Swatch Color",
      handle: "swatch-color",
      base_attribute: color,
      values: [red],
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

  def base_attribute
    @base_attribute ||= build(:attribute)
  end

  def extended_attribute
    @extended_attribute ||= build(:attribute, base_attribute:)
  end
end
