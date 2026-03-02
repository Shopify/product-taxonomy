# frozen_string_literal: true

require_relative "../test_helper"

module ProductTaxonomy
  class OrphanDetectionTest < ActiveSupport::TestCase
    setup do
      ProductTaxonomy::Loader.load(data_path: ProductTaxonomy.data_path)
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
      # Attributes intentionally not assigned to any category. These are either:
      # - Extended attributes that duplicate a base attribute already on the category
      # - Attributes too specific for a parent category (would not apply to all children)
      known_orphan_attributes = [
        "accessory_material",
        "arrow/bolt_material",
        "binocular/monocular_design",
        "book/file_cover_material",
        "chair/sofa_features",
        "coffee_filter_basket_size",
        "diaper_type",
        "disposable/reusable_item_material",
        "door/frame_application",
        "mat/rug_shape",
        "paintball/airsoft_equipment_included",
        "pet_apparel/bedding_features",
        "popcorn_kernel_variety",
        "pole/post_material",
        "timepiece_features",
        "washer/dryer_features",
        "watch/band_material",
      ].sort.freeze

      all_category_attributes = Category.all.flat_map(&:attributes).uniq
      orphan_attributes = Attribute.all.reject { |attr| all_category_attributes.include?(attr) }

      orphan_ids = orphan_attributes.map(&:friendly_id).sort
      unexpected_orphans = orphan_ids - known_orphan_attributes
      message = "Found #{unexpected_orphans.size} unexpected orphan attribute(s) not assigned to any category:\n" \
                "  #{unexpected_orphans.join("\n  ")}"

      assert_empty unexpected_orphans, message
    end
  end
end
