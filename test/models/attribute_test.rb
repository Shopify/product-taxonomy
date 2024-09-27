# frozen_string_literal: true

require_relative "../test_helper"

class AttributeTest < ActiveSupport::TestCase
  def setup
    Attribute.stubs(:localizations).returns({})
    Value.stubs(:localizations).returns({})
  end

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
    base = create(:attribute, name: "Base", base_attribute: nil)
    create(:attribute, name: "Extended", base_attribute: base)

    assert_equal [base], Attribute.base
  end

  test ".extended returns attributes based off others" do
    base = create(:attribute, name: "Base", base_attribute: nil)
    extended = create(:attribute, name: "Extended", base_attribute: base)

    assert_equal [extended], Attribute.extended
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyAttribute/42", build(:attribute, id: 42).gid
  end

  test "#gid returns base_attribute.gid when extended" do
    base = build(:attribute, id: 1, name: "Base", base_attribute: nil)
    extended = build(:attribute, id: 2, name: "Extended", base_attribute: base)

    refute_equal base.id, extended.id
    assert_equal base.gid, extended.gid
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
      {
        "id" => 1,
        "name" => "Color",
        "friendly_id" => "color",
        "handle" => "color",
        "description" => "Description for Color",
      },
      {
        "id" => 2,
        "name" => "Size",
        "friendly_id" => "size",
        "handle" => "size",
        "description" => "Description for Size",
      },
    ]

    assert_difference -> { Attribute.count }, 2 do
      Attribute.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    red = build(:value, name: "Red", handle: "color-red")
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
            "description" => "Description for Color",
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
                "handle" => "color-red",
              },
            ],
          },
        ],
      },
      Attribute.as_json([color], version: 1),
    )
  end

  test ".as_json returns distribution json with values sorted in predetermined custom order" do
    small = build(:value, name: "Small (S)", handle: "size__small-s", friendly_id: "size__small_s", position: 0)
    medium = build(:value, name: "Medium (M)", handle: "size__medium-m", friendly_id: "size__medium_m", position: 1)
    large = build(:value, name: "Large (L)", handle: "size__large-l", friendly_id: "size__large_l", position: 2)
    size = create(:attribute, name: "Size", values: [large, medium, small])

    attributes_json = Attribute.as_json([size], version: 1)

    assert_equal ["Small (S)", "Medium (M)", "Large (L)"],
      attributes_json.dig("attributes", 0, "values").map { _1["name"] }
  end

  test ".as_json returns distribution json with values sorted in predetermined custom order for other locales" do
    Value.unstub(:localizations)

    small = build(:value, name: "Small (S)", handle: "size__small-s", friendly_id: "size__small_s", position: 0)
    medium = build(:value, name: "Medium (M)", handle: "size__medium-m", friendly_id: "size__medium_m", position: 1)
    large = build(:value, name: "Large (L)", handle: "size__large-l", friendly_id: "size__large_l", position: 2)
    size = create(:attribute, name: "Size", values: [large, medium, small])

    attributes_json = Attribute.as_json([size], version: 1, locale: "fr")

    assert_equal ["Petite taille (S)", "Taille moyenne (M)", "Taille large (L)"],
      attributes_json.dig("attributes", 0, "values").map { _1["name"] }
  end

  test ".as_txt returns padded and version string representation" do
    color = create(:attribute, name: "Color")
    size = create(:attribute, name: "Size")

    ids = [color.id, size.id]
    lpad = ids.map { _1.to_s.size }.max
    color_id, size_id = ids.map { _1.to_s.ljust(lpad) }

    assert_equal <<~TXT.strip, Attribute.as_txt([color, size], version: 1)
      # Shopify Product Taxonomy - Attributes: 1
      # Format: {GID} : {Attribute name}

      gid://shopify/TaxonomyAttribute/#{color_id} : Color
      gid://shopify/TaxonomyAttribute/#{size_id} : Size
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
        "description" => "Description for Color",
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
        "description" => "Description for Swatch Color",
        "friendly_id" => "swatch-color",
        "values_from" => "color",
      },
      swatch_color.as_json_for_data,
    )
  end

  test "#as_json returns attributes' values sorted alphanumerically" do
    red = build(:value, name: "Red", handle: "color__red", friendly_id: "color__red")
    blue = build(:value, name: "Blue", handle: "color__blue", friendly_id: "color__blue")
    green = build(:value, name: "Green", handle: "color__green", friendly_id: "color__green")
    color = create(:attribute, name: "Color", values: [blue, green, red])

    color_json = color.as_json["values"]

    assert_equal ["Blue", "Green", "Red"], color_json.map { _1["name"] }
  end

  test "#as_json returns attributes' values sorted alphanumerically for all locales" do
    Value.unstub(:localizations)

    red = build(:value, name: "Red", handle: "color__red", friendly_id: "color__red")
    blue = build(:value, name: "Blue", handle: "color__blue", friendly_id: "color__blue")
    green = build(:value, name: "Green", handle: "color__green", friendly_id: "color__green")
    color = create(:attribute, name: "Color", values: [blue, green, red])

    color_json = color.as_json(locale: "fr")["values"]

    assert_equal ["Bleu", "Rouge", "Vert"], color_json.map { _1["name"] }
  end

  test "#as_json returns attributes' values with `other` listed last for all locales" do
    Value.unstub(:localizations)

    animal = build(:value, name: "Animal", handle: "pattern__animal", friendly_id: "pattern__animal")
    striped = build(:value, name: "Striped", handle: "pattern__striped", friendly_id: "pattern__striped")
    other = build(:value, name: "Other", handle: "pattern__other", friendly_id: "pattern__other")
    pattern = create(:attribute, name: "Pattern", values: [striped, animal, other])

    pattern_json = pattern.as_json(locale: "fr")["values"]

    assert_equal ["Animal", "Rayé", "Autre"], pattern_json.map { _1["name"] }
  end

  test "raises error when value names are provided with base attribute" do
    base_attribute = create(:attribute)
    assert_raises(RuntimeError, "Value names are not allowed when extending a base attribute") do
      Attribute.find_or_create!(
        "Test Attribute",
        "Description",
        base_attribute: base_attribute,
        value_names: ["Value1"],
      )
    end
  end

  test "raises error when value names are missing for base attribute creation" do
    assert_raises(RuntimeError, "Value names are required when creating a base attribute") do
      Attribute.find_or_create!("Test Attribute", "Description", value_names: [])
    end
  end

  test "raises error when attribute already exists" do
    create(:attribute, name: "Material")
    assert_raises(RuntimeError, "Attribute already exists") do
      Attribute.find_or_create!("Material", "Description", value_names: ["Value1"])
    end
  end

  test "creates a new base attribute with values" do
    assert_difference "Attribute.count", 1 do
      assert_difference "Value.count", 2 do
        Attribute.find_or_create!("Test Attribute", "Description", value_names: ["Value1", "Value2"])
      end
    end
    attribute = Attribute.find_by(friendly_id: "test_attribute")
    assert_not_nil attribute
    assert_equal ["Value1", "Value2"], attribute.values.map(&:name)
  end

  test "creates a new extended attribute from base attribute" do
    base_attribute = Attribute.new_from_data(
      "id" => 1,
      "name" => "Color",
      "friendly_id" => "color",
      "handle" => "color",
    )

    Value.find_or_create_for_attribute!(base_attribute, "Blue")
    Value.find_or_create_for_attribute!(base_attribute, "Green")

    assert_difference "Attribute.count", 1 do
      assert_no_difference "Value.count" do
        Attribute.find_or_create!("Extended Attribute", "Description", base_attribute: base_attribute)
      end
    end
    attribute = Attribute.find_by(friendly_id: "extended_attribute")
    assert_not_nil attribute
    assert_equal ["Blue", "Green"], attribute.values.map(&:name)
  end

  private

  def base_attribute
    @base_attribute ||= build(:attribute)
  end

  def extended_attribute
    @extended_attribute ||= build(:attribute, base_attribute:)
  end
end
