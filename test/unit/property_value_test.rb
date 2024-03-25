# frozen_string_literal: true

require_relative "../test_helper"

class PropertyValueTest < ActiveSupport::TestCase
  def teardown
    PropertyValue.destroy_all
  end

  test "#gid returns a global id" do
    assert_equal "gid://shopify/Taxonomy/Value/12", value(id: 12).gid
  end

  test "default ordering is alphabetical with 'other' last" do
    red = value!(id: 11, name: "Red", friendly_id: "test__red")
    zoo = value!(id: 12, name: "Zoo", friendly_id: "test__zoo")
    other = value!(id: 10, name: "Other", friendly_id: "test__other")

    assert_equal [red, zoo, other], PropertyValue.all.to_a
  end

  private

  def value(id: 1, name: "Foo", friendly_id: "test__foo")
    PropertyValue.new(id: id, name: name, friendly_id: friendly_id)
  end

  def value!(id: 1, name: "Foo", friendly_id: "test__foo")
    PropertyValue.create(id: id, name: name, friendly_id: friendly_id)
  end
end
