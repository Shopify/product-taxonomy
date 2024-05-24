# frozen_string_literal: true

require_relative "../test_helper"

class ValueTest < ActiveSupport::TestCase
  def setup
    Attribute.stubs(:localizations).returns({})
    Value.stubs(:localizations).returns({})
  end

  def teardown
    Attribute.delete_all
    Value.delete_all
  end

  test "default ordering is alphabetical with 'Other' last" do
    other = create(:value, name: "Other")
    zoo = create(:value, name: "Zoo")
    red = create(:value, name: "Red")

    assert_equal [red, zoo, other], Value.all.to_a
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyValue/42", build(:value, id: 42).gid
  end

  test "#full_name returns the name of the primary attribute and the value" do
    assert_equal "Gold [Color]", build(:value, name: "Gold", primary_attribute: color_attribute).full_name
  end

  test "#friendly_id must be unique" do
    create(:value, friendly_id: "wonderful-gold")
    another_gold = build(:value, friendly_id: "wonderful-gold")

    refute_predicate another_gold, :valid?
  end

  test "#handle must be unique per primary attribute" do
    create(:value, handle: "gold", primary_attribute: color_attribute)
    another_gold = build(:value, handle: "gold", primary_attribute: color_attribute)

    refute_predicate another_gold, :valid?
  end

  test "#handle can be duplicated across different primary attributes" do
    create(:value, handle: "gold", primary_attribute: color_attribute)
    material_gold = build(:value, handle: "gold", primary_attribute: build(:attribute, name: "Material"))

    assert_predicate material_gold, :valid?
  end

  test ".new_from_data creates a new attribute value" do
    color_attribute.save!
    attribute_value = Value.new_from_data(
      "id" => 1,
      "name" => "Gold",
      "handle" => "gold",
      "friendly_id" => "color__gold",
    )

    assert_equal 1, attribute_value.id
    assert_equal "Gold", attribute_value.name
    assert_equal "gold", attribute_value.handle
    assert_equal "color__gold", attribute_value.friendly_id
    assert_equal "color", attribute_value.primary_attribute_friendly_id
  end

  test ".insert_all_from_data creates multiple categories" do
    data = [
      { "id" => 1, "name" => "Gold", "handle" => "gold", "friendly_id" => "color__gold" },
      { "id" => 2, "name" => "Red", "handle" => "red", "friendly_id" => "color__red" },
    ]

    assert_difference -> { Value.count }, 2 do
      Value.insert_all_from_data(data)
    end
  end

  test ".as_json returns distribution json" do
    gold = create(:value, name: "Gold", handle: "color-gold")
    red = create(:value, name: "Red", handle: "color-red")

    assert_equal(
      {
        "version" => 1,
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/#{gold.id}",
            "name" => "Gold",
            "handle" => "color-gold",
          },
          {
            "id" => "gid://shopify/TaxonomyValue/#{red.id}",
            "name" => "Red",
            "handle" => "color-red",
          },
        ],
      },
      Value.as_json([gold, red], version: 1),
    )
  end

  test ".as_txt returns padded and version string representation" do
    gold = create(:value, name: "Gold", primary_attribute: color_attribute)
    red = create(:value, name: "Red", primary_attribute: color_attribute)

    assert_equal <<~TXT.strip, Value.as_txt([gold, red], version: 1)
      # Shopify Product Taxonomy - Attribute Values: 1
      # Format: {GID} : {Value name} [{Attribute name}]

      gid://shopify/TaxonomyValue/#{gold.id} : Gold [Color]
      gid://shopify/TaxonomyValue/#{red.id} : Red [Color]
    TXT
  end

  test "#as_json_for_data returns data json" do
    gold = create(:value, name: "Gold", primary_attribute: color_attribute)

    assert_equal(
      {
        "id" => gold.id,
        "name" => "Gold",
        "friendly_id" => "color__gold",
        "handle" => "color-gold",
      },
      gold.as_json_for_data,
    )
  end

  private

  def color_attribute
    @color_attribute ||= build(:attribute, name: "Color")
  end
end
