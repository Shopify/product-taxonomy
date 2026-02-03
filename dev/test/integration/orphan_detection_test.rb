# frozen_string_literal: true

require_relative "../test_helper"

module ProductTaxonomy
  class OrphanDetectionTest < ActiveSupport::TestCase
    parallelize(workers: 1)

    @@taxonomy_loaded = false

    setup do
      unless @@taxonomy_loaded
        Command.new(quiet: true).load_taxonomy
        @@taxonomy_loaded = true
      end
    end

    test "All values are referenced by at least one attribute" do
      orphan_values = Value.all.reject do |value|
        value.primary_attribute&.values&.include?(value)
      end

      orphan_ids = orphan_values.map(&:friendly_id).sort
      message = "Found #{orphan_ids.size} orphan value(s) not referenced by any attribute:\n" \
                "  #{orphan_ids.join("\n  ")}"

      assert_empty orphan_ids, message
    end

    test "All attributes belong to at least one category" do
      all_category_attributes = Category.all.flat_map(&:attributes).uniq
      orphan_attributes = Attribute.all.reject { |attr| all_category_attributes.include?(attr) }

      orphan_ids = orphan_attributes.map(&:friendly_id).sort
      message = "Found #{orphan_ids.size} orphan attribute(s) not assigned to any category:\n" \
                "  #{orphan_ids.join("\n  ")}"

      assert_empty orphan_ids, message
    end

    test "All return reasons belong to at least one category" do
      all_category_return_reasons = Category.all.flat_map(&:return_reasons).uniq
      orphan_return_reasons = ReturnReason.all.reject { |rr| all_category_return_reasons.include?(rr) }

      orphan_ids = orphan_return_reasons.map(&:friendly_id).sort
      message = "Found #{orphan_ids.size} orphan return reason(s) not assigned to any category:\n" \
                "  #{orphan_ids.join("\n  ")}"

      assert_empty orphan_ids, message
    end
  end
end
