# frozen_string_literal: true

require_relative "../test_helper"

module ProductTaxonomy
  class AllDataFilesImportTest < ActiveSupport::TestCase
    include Minitest::Hooks
    parallelize(workers: 1) # disable parallelization
    # I don't _actually_ suck ;-) we need this so that we can load the data a single time to use for all tests in this
    # class using before_all, giving better performance.
    i_suck_and_my_tests_are_order_dependent!

    def before_all
      @raw_values_data = YAML.safe_load_file(File.expand_path("values.yml", ProductTaxonomy::DATA_PATH))
      @raw_attributes_data = YAML.safe_load_file(File.expand_path("attributes.yml", ProductTaxonomy::DATA_PATH))
      @raw_verticals_data = Dir.glob(File.expand_path("categories/*.yml", ProductTaxonomy::DATA_PATH))
        .map { |file| YAML.safe_load_file(file) }
      @raw_integrations_data = YAML.safe_load_file(File.expand_path(
        "integrations/integrations.yml",
        ProductTaxonomy::DATA_PATH,
      ))
      mapping_rule_files = Dir.glob(File.expand_path(
        "integrations/*/*/mappings/*_shopify.yml",
        ProductTaxonomy::DATA_PATH,
      ))
      @raw_mapping_rules_data = mapping_rule_files.map { { content: YAML.safe_load_file(_1), file_name: _1 } }

      Command.new(quiet: true).load_taxonomy
    end

    def after_all
      Value.reset
      Attribute.reset
      Category.reset
    end

    test "Values are consistent with values.yml" do
      @raw_values_data.each do |raw_value|
        real_value = Value.find_by(id: raw_value.fetch("id"))

        refute_nil real_value, "Value #{raw_value.fetch("id")} not found"
        assert_equal raw_value["id"], real_value.id
        assert_equal raw_value["name"], real_value.name
        assert_equal raw_value["handle"], real_value.handle
        assert_equal raw_value["friendly_id"], real_value.friendly_id
      end
    end

    test "Attributes are consistent with attributes.yml" do
      base_attributes = @raw_attributes_data["base_attributes"]
      extended_attributes = @raw_attributes_data["extended_attributes"]

      base_attributes.each do |raw_attribute|
        real_attribute = Attribute.find_by(friendly_id: raw_attribute.fetch("friendly_id"))

        refute_nil real_attribute, "Attribute #{raw_attribute.fetch("friendly_id")} not found"
        assert_equal raw_attribute["name"], real_attribute.name
        assert_equal raw_attribute["handle"], real_attribute.handle
        assert_equal raw_attribute["description"], real_attribute.description
        assert_equal raw_attribute["friendly_id"], real_attribute.friendly_id
        assert_equal raw_attribute["values"], real_attribute.values.map(&:friendly_id)
      end

      extended_attributes.each do |raw_attribute|
        real_attribute = Attribute.find_by(friendly_id: raw_attribute.fetch("friendly_id"))

        refute_nil real_attribute, "Attribute #{raw_attribute.fetch("friendly_id")} not found"
        assert_equal raw_attribute["name"], real_attribute.name
        assert_equal raw_attribute["handle"], real_attribute.handle
        assert_equal raw_attribute["description"], real_attribute.description
        assert_equal raw_attribute["friendly_id"], real_attribute.friendly_id
        assert_equal raw_attribute["values_from"], real_attribute.values_from.friendly_id
      end
    end

    test "Categories are consistent with categories/*.yml" do
      @raw_verticals_data.flatten.each do |raw_category|
        real_category = Category.find_by(id: raw_category.fetch("id"))

        refute_nil real_category, "Category #{raw_category.fetch("id")} not found"
        assert_equal raw_category.fetch("id"), real_category.id
        assert_equal raw_category.fetch("name"), real_category.name
        assert_equal raw_category.fetch("children").size, real_category.children.count
        assert_equal raw_category.fetch("children").sort, real_category.children.map(&:id).sort
        assert_equal raw_category.fetch("attributes").sort, real_category.attributes.map(&:friendly_id).sort
        assert_equal raw_category.fetch("secondary_children", []).sort, real_category.secondary_children.map(&:id).sort
      end
    end

    # more fragile, but easier sanity check
    test "Snowboards category <sg-4-17-2-17> is fully imported and modeled correctly" do
      snowboard = Category.find_by(id: "sg-4-17-2-17")

      assert_equal "Snowboards", snowboard.name
      assert_empty snowboard.children

      real_attribute_friendly_ids = snowboard.attributes.map(&:friendly_id)
      assert_equal 8, real_attribute_friendly_ids.size
      assert_includes real_attribute_friendly_ids, "age_group"
      assert_includes real_attribute_friendly_ids, "color"
      assert_includes real_attribute_friendly_ids, "pattern"
      assert_includes real_attribute_friendly_ids, "recommended_skill_level"
      assert_includes real_attribute_friendly_ids, "snowboard_design"
      assert_includes real_attribute_friendly_ids, "snowboarding_style"
      assert_includes real_attribute_friendly_ids, "target_gender"
      assert_includes real_attribute_friendly_ids, "snowboard_construction"
    end

    # more fragile, but easier sanity check
    test "Snowboard construction attribute <snowboard_construction> is fully imported and modeled correctly" do
      snowboard_construction = Attribute.find_by(friendly_id: "snowboard_construction")

      assert_equal "Snowboard construction", snowboard_construction.name
      assert_equal "snowboard_construction", snowboard_construction.friendly_id

      real_value_friendly_ids = snowboard_construction.values.map(&:friendly_id)
      assert_equal 5, real_value_friendly_ids.size
      assert_includes real_value_friendly_ids, "snowboard_construction__camber"
      assert_includes real_value_friendly_ids, "snowboard_construction__flat"
      assert_includes real_value_friendly_ids, "snowboard_construction__hybrid"
      assert_includes real_value_friendly_ids, "snowboard_construction__rocker"
    end
  end
end
