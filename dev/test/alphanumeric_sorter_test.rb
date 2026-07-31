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

      assert_equal(
        [
          "CCS1-bilindtag til CHAdeMO-stik",
          "CCS1-bilindtag til J1772-stik",
        ],
        AlphanumericSorter.sort(names),
      )
    end

    test "normalize_value never returns a nil sort-key slot for any name shape" do
      shapes = [
        "Red",                                # plain text
        "Red-Blue",                           # separator with no digits
        "Size 1-2",                           # sequential text with a full range
        "2x large",                           # number with a unit
        "100",                                # bare number
        "2 5/8 in",                           # fraction with a unit
        "10x20 cm",                           # numeric dimension
        "CCS1-bilindtag til CHAdeMO-stik",    # sequential, unmatched secondary text
        "CCS1-bilindtag til J1772-stik",      # sequential, matched secondary text
        "Type 2-bilindtag (Mennekes) til Type 1-stik (J1772)",
        "abc-",                               # trailing separator
        "-abc",                               # leading separator
      ]

      shapes.each do |shape|
        AlphanumericSorter.normalize_value(shape).each_with_index do |slot, index|
          assert(
            slot.is_a?(String) || slot.is_a?(Numeric),
            "Sort-key slot #{index} for #{shape.inspect} is #{slot.inspect}; " \
              "nil slots make Array#<=> fail during sort",
          )
        end
      end
    end
  end
end
