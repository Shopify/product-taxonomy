# frozen_string_literal: true

require_relative "../test_helper"

class PropertyValueTest < ActiveSupport::TestCase
  def teardown
    Property.destroy_all
    PropertyValue.destroy_all
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyValue/12", value(id: 12).gid
  end

  test "default ordering is alphabetical with 'other' last" do
    red = value!(id: 11, name: "Red", friendly_id: "test__red", handle: "red")
    zoo = value!(id: 12, name: "Zoo", friendly_id: "test__zoo", handle: "zoo")
    other = value!(id: 10, name: "Other", friendly_id: "test__other", handle: "other")

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end

  test "#full_name returns the name of the primary property and the value" do
    color = Property.create!(name: "Color", friendly_id: "color", handle: "color")
    red = value!(name: "Red", friendly_id: "color__red", primary_property: color)

    assert_equal "Red [Color]", red.full_name
  end

  test "#full_name is just name if primary property is missing" do
    red = value!(name: "Red", friendly_id: "color__red", handle: "red")

    assert_equal "Red", red.full_name
  end

  test "#handle must be unique per primary friendly id" do
    Property.create!(name: "Bar", friendly_id: "bar", handle: "bar")
    value!(handle: "foo", primary_property_friendly_id: "bar")
    assert_raises(ActiveRecord::RecordInvalid) { value!(id: 2, handle: "foo", primary_property_friendly_id: "bar") }
  end

  test "handle can be duplicated across different primary property friendly ids" do
    Property.create!(name: "Bat", friendly_id: "bat", handle: "bat")
    Property.create!(name: "Baz", friendly_id: "baz", handle: "baz")
    value!(handle: "foo", primary_property_friendly_id: "bar")
    value!(id: 2, friendly_id: "test_boo", handle: "foo", primary_property_friendly_id: "baz")
  end

  private

  def value(**args)
    default_args = {
      id: 1,
      name: "Foo",
      friendly_id: "test__foo",
      handle: "foo",
    }
    PropertyValue.new(default_args.merge(args))
  end

  def value!(**args)
    value(**args).tap(&:save!)
  end
end
