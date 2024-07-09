# frozen_string_literal: true

require_relative "../test_helper"

class ValueSorterTest < ActiveSupport::TestCase
  def teardown
    Attribute.delete_all
    Value.delete_all
  end

  test ".sort sorts values by position if present" do
    size = construct_size_attribute

    sorted_values = ValueSorter.sort(size.values)

    assert_equal ["Small (S)", "Medium (M)", "Large (L)"], sorted_values.map(&:name)
  end

  test ".sort sorts non-English values by position if present" do
    size = construct_size_attribute

    sorted_values = ValueSorter.sort(size.values, locale: "fr")

    assert_equal ["Petite taille (S)", "Taille moyenne (M)", "Taille large (L)"],
      sorted_values.map { _1.name(locale: "fr") }
  end

  test ".sort sorts values alphanumerically" do
    color = construct_color_attribute

    sorted_values = ValueSorter.sort(color.values)

    assert_equal ["Blue", "Green", "Red"], sorted_values.map(&:name)
  end

  test ".sort sorts non-English values alphanumerically" do
    color = construct_color_attribute

    sorted_values = ValueSorter.sort(color.values, locale: "fr")

    assert_equal ["Bleu", "Rouge", "Vert"], sorted_values.map { _1.name(locale: "fr") }
  end

  test ".sort sorts values with 'Other' at the end" do
    pattern = construct_pattern_attribute

    sorted_values = ValueSorter.sort(pattern.values)

    assert_equal ["Animal", "Striped", "Other"], sorted_values.map(&:name)
  end

  test ".sort sorts non-English values with 'Other' at the end" do
    pattern = construct_pattern_attribute

    sorted_values = ValueSorter.sort(pattern.values, locale: "fr")

    assert_equal ["Animal", "Rayé", "Autre"], sorted_values.map { _1.name(locale: "fr") }
  end

  private

  def construct_color_attribute
    red = build(:value, name: "Red", handle: "color__red", friendly_id: "color__red")
    blue = build(:value, name: "Blue", handle: "color__blue", friendly_id: "color__blue")
    green = build(:value, name: "Green", handle: "color__green", friendly_id: "color__green")

    create(:attribute, name: "Color", handle: "color", values: [red, blue, green])
  end

  def construct_pattern_attribute
    animal = build(:value, name: "Animal", handle: "pattern__animal", friendly_id: "pattern__animal")
    striped = build(:value, name: "Striped", handle: "pattern__striped", friendly_id: "pattern__striped")
    other = build(:value, name: "Other", handle: "pattern__other", friendly_id: "pattern__other")

    create(:attribute, name: "Pattern", values: [striped, animal, other])
  end

  def construct_size_attribute
    small = build(:value, name: "Small (S)", handle: "size__small-s", friendly_id: "size__small_s", position: 0)
    medium = build(:value, name: "Medium (M)", handle: "size__medium-m", friendly_id: "size__medium_m", position: 1)
    large = build(:value, name: "Large (L)", handle: "size__large-l", friendly_id: "size__large_l", position: 2)

    create(:attribute, name: "Size", values: [medium, large, small])
  end
end
