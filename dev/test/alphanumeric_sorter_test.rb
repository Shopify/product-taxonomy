# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AlphanumericSorterTest < TestCase
    test "sort orders single-word values alphabetically" do
      assert_equal(["Blue", "Green", "Red"], AlphanumericSorter.sort(["Red", "Green", "Blue"]))
    end

    test "sort orders numeric values numerically rather than lexically" do
      assert_equal(["2", "10", "100"], AlphanumericSorter.sort(["100", "2", "10"]))
    end

    test "sort moves 'other' to the end when other_last is set" do
      assert_equal(
        ["Animal", "Striped", "Other"],
        AlphanumericSorter.sort(["Other", "Striped", "Animal"], other_last: true),
      )
    end

    test "sort handles a set mixing names with and without a matched secondary-text segment" do
      names = [
        "CCS1-bilindtag til J1772-stik",
        "CCS1-bilindtag til CHAdeMO-stik",
      ]

      sorted = nil
      assert_nothing_raised { sorted = AlphanumericSorter.sort(names) }

      assert_equal(
        [
          "CCS1-bilindtag til CHAdeMO-stik",
          "CCS1-bilindtag til J1772-stik",
        ],
        sorted,
      )
    end
  end
end
