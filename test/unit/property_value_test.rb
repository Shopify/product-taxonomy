# frozen_string_literal: true

require_relative "../test_helper"

class PropertyValueTest < ActiveSupport::TestCase
  def teardown
    PropertyValue.destroy_all
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/TaxonomyValue/12", value(id: 12).gid
  end

  test "default ordering is alphabetical with 'other' last" do
    red = value!(id: 11, name: "Red", friendly_id: "test__red")
    zoo = value!(id: 12, name: "Zoo", friendly_id: "test__zoo")
    other = value!(id: 10, name: "Other", friendly_id: "test__other")

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end

  test "#full_name returns the name of the primary property and the value" do
    color = Property.create!(name: "Color", friendly_id: "color")
    red = value!(name: "Red", friendly_id: "color__red", primary_property: color)

    assert_equal "Color > Red", red.full_name
  end

  test "#full_name is just name if primary property is missing" do
    red = value!(name: "Red", friendly_id: "color__red")

    assert_equal "Red", red.full_name
  end

  private

  def value(**args)
    default_args = { id: 1, name: "Foo", friendly_id: "test__foo" }
    PropertyValue.new(default_args.merge(args))
  end

  def value!(**args)
    default_args = { id: 1, name: "Foo", friendly_id: "test__foo" }
    PropertyValue.create(default_args.merge(args))
  end
end
