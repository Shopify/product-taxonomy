# frozen_string_literal: true

require_relative "../test_helper"

class PropertyTest < ApplicationTestCase
  def teardown
    Property.delete_all
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

  private

  def base_property
    @base_property ||= build(:property)
  end

  def extended_property
    @extended_property ||= build(:property, base_property:)
  end
end
