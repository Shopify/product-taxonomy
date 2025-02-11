# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class IdentifierFormatterTest < TestCase
    test "format_friendly_id with special characters" do
      assert_equal "apparel_accessories", IdentifierFormatter.format_friendly_id("Apparel & Accessories")
    end

    test "format_handle with special characters" do
      assert_equal "apparel-accessories", IdentifierFormatter.format_handle("Apparel & Accessories")
    end

    test "format_handle with plus in name" do
      assert_equal "c-plus-plus-programming", IdentifierFormatter.format_handle("C++ Programming")
    end

    test "format_handle with hashtag in name" do
      assert_equal "trending-hashtag-products", IdentifierFormatter.format_handle("Trending #Products")
    end

    test "format_handle with multiple dashes" do
      assert_equal "arcade-gaming", IdentifierFormatter.format_handle("Arcade --- & Gaming")
    end
  end
end
