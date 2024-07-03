# frozen_string_literal: true

require_relative "../test_helper"

GEM_INSTALLED = begin
  require "filter_values_sorter"
  true
rescue LoadError
  false
end

class ValueSorterTest < ActiveSupport::TestCase
  test "custom sorts size-based attribute values with gem installed" do
    values = [
      create(:value, name: "large"),
      create(:value, name: "medium"),
      create(:value, name: "small"),
    ]

    skip("FilterValuesSorter gem is not available") unless GEM_INSTALLED

    ValueSorter.stub_const(:GEM_AVAILABLE, true) do
      sorted_values = ValueSorter.sort_values_for_attribute("size", values)
      expected_sorted_values = ["small", "medium", "large"]

      assert_equal(expected_sorted_values, sorted_values.map(&:name))
    end
  end

  test "sorts values alphanumerically for non-size-based attributes with gem installed" do
    values = [
      create(:value, name: "10"),
      create(:value, name: "2"),
      create(:value, name: "1"),
      create(:value, name: "foo"),
    ]

    skip("FilterValuesSorter gem is not available") unless GEM_INSTALLED

    ValueSorter.stub_const(:GEM_AVAILABLE, true) do
      sorted_values = ValueSorter.sort_values_for_attribute("misc", values)
      expected_sorted_values = ["1", "2", "10", "foo"]

      assert_equal(expected_sorted_values, sorted_values.map(&:name))
    end
  end

  test "#sort_values_for_attribute sorts other last" do
    values = [
      create(:value, name: "red"),
      create(:value, name: "green"),
      create(:value, name: "blue"),
      create(:value, name: "other"),
    ]

    skip("FilterValuesSorter gem is not available") unless GEM_INSTALLED

    ValueSorter.stub_const(:GEM_AVAILABLE, true) do
      sorted_values = ValueSorter.sort_values_for_attribute("color", values)
      expected_sorted_values = ["blue", "green", "red", "other"]

      assert_equal(expected_sorted_values, sorted_values.map(&:name))
    end
  end

  test "doesn't sort values without gem installed" do
    values = [
      create(:value, name: "large"),
      create(:value, name: "medium"),
      create(:value, name: "small"),
    ]

    ValueSorter.stub_const(:GEM_AVAILABLE, false) do
      sorted_values = ValueSorter.sort_values_for_attribute("size", values)
      expected_sorted_values = ["large", "medium", "small"]

      assert_equal(expected_sorted_values, sorted_values.map(&:name))
    end
  end
end
