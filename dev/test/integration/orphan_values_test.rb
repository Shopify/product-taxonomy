# frozen_string_literal: true

require_relative "../test_helper"

module ProductTaxonomy
  class OrphanValuesTest < ActiveSupport::TestCase
    include Minitest::Hooks
    parallelize(workers: 1)

    def before_all
      Command.new(quiet: true).load_taxonomy
    end

    def after_all
      Value.reset
      Attribute.reset
      Category.reset
      ReturnReason.reset
    end

    test "All values are referenced by at least one attribute" do
      orphan_values = Value.all.reject do |value|
        value.primary_attribute&.values&.include?(value)
      end

      unless orphan_values.empty?
        puts "Found #{orphan_values.size} orphan value(s) not referenced by any attribute:"
        orphan_values.each { |v| puts "  - #{v.friendly_id}" }
        puts ""
        puts "These values exist in data/values.yml but are not listed in any attribute's"
        puts "values array in data/attributes.yml."
      end

      assert_empty orphan_values, "Orphan values found. See output above for details."
    end
  end
end
