# frozen_string_literal: true

require_relative "../test_helper"

class PropertyValueTest < ApplicationTestCase
  def teardown
    Property.delete_all
    PropertyValue.delete_all
  end

  test "default ordering is alphabetical with 'Other' last" do
    other = create(:property_value, name: "Other")
    zoo = create(:property_value, name: "Zoo")
    red = create(:property_value, name: "Red")

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyValue/42", build(:property_value, id: 42).gid
  end

  test "#full_name returns the name of the primary property and the value" do
    assert_equal "Gold [Color]", build(:property_value, name: "Gold", primary_property: color_property).full_name
  end

  test "#full_name is just name if primary property is missing" do
    assert_equal "Foo", build(:property_value, name: "Foo").full_name
  end

  test "#friendly_id must be unique" do
    create(:property_value, friendly_id: "gold")
    another_gold = build(:property_value, friendly_id: "gold")

    refute_predicate another_gold, :valid?
  end

  test "#handle must be unique per primary property" do
    create(:property_value, handle: "gold", primary_property: color_property)
    another_gold = build(:property_value, handle: "gold", primary_property: color_property)

    refute_predicate another_gold, :valid?
  end

  test "#handle can be duplicated across different primary properties" do
    create(:property_value, handle: "gold", primary_property: color_property)
    material_gold = build(:property_value, handle: "gold", primary_property: build(:property, name: "Material"))

    assert_predicate material_gold, :valid?
  end

  test ".new_from_data creates a new property value" do
    color_property.save!
    property_value = PropertyValue.new_from_data(
      "id" => 1,
      "name" => "Gold",
      "handle" => "gold",
      "friendly_id" => "color__gold",
    )

    assert_equal 1, property_value.id
    assert_equal "Gold", property_value.name
    assert_equal "gold", property_value.handle
    assert_equal "color__gold", property_value.friendly_id
    assert_equal "color", property_value.primary_property_friendly_id
  end

  test ".insert_all_from_data creates multiple categories" do
    data = [
      { "id" => 1, "name" => "Gold", "handle" => "gold", "friendly_id" => "color__gold" },
      { "id" => 2, "name" => "Red", "handle" => "red", "friendly_id" => "color__red" },
    ]

    assert_difference -> { PropertyValue.count }, 2 do
      PropertyValue.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    gold = create(:property_value, name: "Gold")
    red = create(:property_value, name: "Red")

    assert_equal(
      {
        "version" => 1,
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/#{gold.id}",
            "name" => "Gold",
            "handle" => "gold",
          },
          {
            "id" => "gid://shopify/TaxonomyValue/#{red.id}",
            "name" => "Red",
            "handle" => "red",
          },
        ],
      },
      PropertyValue.as_json([gold, red], version: 1),
    )
  end

  test ".as_txt returns padded and version string representation" do
    gold = create(:property_value, name: "Gold", primary_property: color_property)
    red = create(:property_value, name: "Red", primary_property: color_property)

    assert_equal <<~TXT.strip, PropertyValue.as_txt([gold, red], version: 1)
      # Shopify Product Taxonomy - Attribute Values: 1
      # Format: {GID} : {Value name} [{Attribute name}]

      gid://shopify/TaxonomyValue/#{gold.id} : Gold [Color]
      gid://shopify/TaxonomyValue/#{red.id} : Red [Color]
    TXT
  end

  test "#as_json_for_data returns data json" do
    gold = create(:property_value, name: "Gold", primary_property: color_property)

    assert_equal(
      {
        "id" => gold.id,
        "name" => "Gold",
        "friendly_id" => "color__gold",
        "handle" => "gold",
      },
      gold.as_json_for_data,
    )
  end

  private

  def color_property
    @color_property ||= build(:property, name: "Color")
  end
end
