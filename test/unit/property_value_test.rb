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

  private

  def color_property
    @color_property ||= build(:property, name: "Color")
  end
end
