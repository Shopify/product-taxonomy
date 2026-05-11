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
      known_orphan_attributes = [
        "accessory_material",
        "archery_target_type",
        "arrow/bolt_material",
        "baby/toddler_equipment_safety_features",
        "bag_insulation",
        "bakeware_features",
        "bakeware_pieces_included",
        "binocular/monocular_design",
        "book/file_cover_material",
        "bottle_warmer/sterilizer_features",
        "bow_material",
        "cane_base_design",
        "chair/sofa_features",
        "changing_mat/tray_features",
        "clay/slip_texture",
        "coffee_filter_basket_size",
        "console_system",
        "cookware_coating_material",
        "cookware_features",
        "diaper_cover_style",
        "diaper_type",
        "disposable/reusable_item_material",
        "door/frame_application",
        "eu_children_clothing_size",
        "eu_clothing_size",
        "eu_cup_size",
        "eu_ring_size",
        "eu_shoe_size",
        "fiber_optic_mode",
        "foot_coverage",
        "fuel_compatibility",
        "grater_design",
        "hand_and_foot_coverage",
        "hearing_aid_ear_side",
        "insulation_status",
        "knit_style",
        "knitting/padding_project_type",
        "leak_protection_layer",
        "legging_foot_design",
        "lens/slide_material",
        "long_john_pieces_included",
        "mat/rug_shape",
        "mat_base_material",
        "mold/cut_shape",
        "optical_drive_form_factor",
        "outfit_items_included",
        "paintball/airsoft_equipment_included",
        "pet_apparel/bedding_features",
        "pole/post_material",
        "popcorn_kernel_variety",
        "radio_case_design",
        "recycled_material_content",
        "saddle_material",
        "sleeve_insulation",
        "sole_type",
        "swim_bottom_length",
        "swim_diaper_feature",
        "swimwear_pieces_included",
        "timepiece_features",
        "toilet/bidet_mounting_type",
        "topographical_relief",
        "training_usage_type",
        "transfer_aid_type",
        "uk_childrens_shoe_size",
        "uk_clothing_size",
        "uk_cup_size",
        "uk_mens_shoe_size",
        "uk_womens_shoe_size",
        "underwear_fit",
        "underwear_pieces_included",
        "us_childrens_shoe_size",
        "us_clothing_size",
        "us_cup_size",
        "us_mens_shoe_size",
        "us_ring_size",
        "us_womens_shoe_size",
        "vehicle_engine/part_features",
        "washer/dryer_features",
        "watch/band_material",
        "wax_paper_form",
        "wipe_dispenser/warmer_features",
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
