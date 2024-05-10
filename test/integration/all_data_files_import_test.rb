# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../db/seed"
require_relative "../../lib/cli"

class AllDataFilesImportTest < ActiveSupport::TestCase
  include Minitest::Hooks

  def before_all
    cli = CLI.new
    @raw_values_data = cli.parse_yaml("data/values.yml")
    @raw_attributes_data = cli.parse_yaml("data/attributes.yml")
    category_files = Dir.glob("#{CLI.root}/data/categories/*.yml")
    @raw_verticals_data = category_files.map { cli.parse_yaml(_1) }
    @raw_integrations_data = cli.parse_yaml("data/integrations/integrations.yml")
    mapping_rule_files = Dir.glob("#{CLI.root}/data/integrations/*/*/mappings/*_shopify.yml")
    @raw_mapping_rules_data = mapping_rule_files.map { { content: YAML.load_file(_1), file_name: _1 } }

    seed = DB::Seed.new
    seed.values_from(@raw_values_data)
    seed.attributes_from(@raw_attributes_data)
    seed.categories_from(@raw_verticals_data)
    seed.integrations_from(@raw_integrations_data)
    seed.mapping_rules_from(mapping_rule_files)
  end

  test "data/attributes.yml base_attributes has no empty value lists" do
    @raw_attributes_data["base_attributes"].select { _1.key?("values") }.each do |raw_attribute|
      assert_predicate raw_attribute.fetch("values"), :present?
    end
  end

  test "data/attributes.yaml base attributes do not have values_from key" do
    @raw_attributes_data["base_attributes"].each do |raw_attribute|
      assert raw_attribute.key?("values")
      assert_not raw_attribute.key?("values_from")
    end
  end

  test "data/attributes.yaml extended attributes do not have values key" do
    @raw_attributes_data["extended_attributes"].each do |raw_attribute|
      assert raw_attribute.key?("values_from")
      assert_not raw_attribute.key?("values")
    end
  end

  test "AttributeValues are correctly imported from values.yml" do
    assert_equal @raw_values_data.size, Value.count
  end

  test "AttributeValues are consistent with values.yml" do
    @raw_values_data.each do |raw_value|
      deserialized_value = Value.new_from_data(raw_value)
      real_value = Value.find(raw_value.fetch("id"))

      assert_equal deserialized_value, real_value
    end
  end

  test "AttributeValues are all valid" do
    Value.all.each do |value|
      assert_predicate value, :valid?
    end
  end

  test "AttributeValues all have a primary attribute" do
    Value.all.each do |value|
      assert_predicate value.primary_attribute, :present?, "Value #{value.friendly_id} has no primary attribute"
    end
  end

  test "Attributes are correctly imported from attributes.yml" do
    assert_equal @raw_attributes_data.values.flat_map { _1 }.size, Attribute.count
  end

  test "Attributes are consistent with attributes.yml" do
    base_attributes = @raw_attributes_data["base_attributes"]
    extended_attributes = @raw_attributes_data["extended_attributes"]

    base_attributes.each do |raw_attribute|
      deserialized_attribute = Attribute.new_from_data(raw_attribute)
      real_attribute = Attribute.find(raw_attribute.fetch("id"))

      assert_equal deserialized_attribute, real_attribute
    end

    extended_attributes.each do |raw_attribute|
      deserialized_attribute = Attribute.new_from_data(raw_attribute)
      real_attribute = Attribute.find_by(
        name: raw_attribute.fetch("name"),
        base_friendly_id: raw_attribute.fetch("values_from"),
      )

      assert_equal deserialized_attribute.attributes.except("id"), real_attribute.attributes.except("id")
    end
  end

  test "Exteneded Attributes have primary attributes if they inherit values" do
    @raw_attributes_data["extended_attributes"].each do |raw_attribute|
      next unless raw_attribute.key?("values_from")

      real_attribute = Attribute.find_by(
        name: raw_attribute.fetch("name"),
        base_friendly_id: raw_attribute.fetch("values_from"),
      )
      real_parent_attribute = Attribute.find_by!(friendly_id: raw_attribute.fetch("values_from"))

      assert_equal real_parent_attribute, real_attribute.base_attribute
    end
  end

  test "Attributes are all valid" do
    Attribute.all.each do |attribute|
      assert_predicate attribute, :valid?
    end
  end

  test "Categories are fully imported from categories/*.yml" do
    assert_equal @raw_verticals_data.size, Category.verticals.count
    assert_equal @raw_verticals_data.map(&:size).sum, Category.count
  end

  test "Categories are consistent with categories/*.yml" do
    @raw_verticals_data.flatten.each do |raw_category|
      deserialized_category = Category.new_from_data(raw_category)
      real_category = Category.find(raw_category.fetch("id"))

      assert_equal deserialized_category, real_category
      assert_equal raw_category.fetch("children").size, real_category.children.count
      assert_equal deserialized_category.children, real_category.children
    end
  end

  test "Categories are all valid" do
    Category.all.each do |category|
      assert_predicate category, :valid?
    end
  end

  test "Category ↔ Attribute relationships are consistent with categories/*.yml" do
    @raw_verticals_data.flatten.each do |raw_category|
      properties_via_raw_category_id = Category.find(raw_category.fetch("id")).related_attributes
      properties_via_raw_attributes = raw_category.fetch("attributes").map { Attribute.find_by(friendly_id: _1) }

      assert_equal properties_via_raw_attributes.sort, properties_via_raw_category_id.sort
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml base_attributes" do
    @raw_attributes_data["base_attributes"].select { _1.key?("values") }.each do |raw_attribute|
      values_via_raw_id = Attribute.find(raw_attribute.fetch("id")).values
      values_via_raw_values = raw_attribute.fetch("values").map { Value.find_by(friendly_id: _1) }

      assert_equal values_via_raw_values.sort, values_via_raw_id.sort
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml they are extended" do
    @raw_attributes_data["extended_attributes"].select { _1.key?("values_from") }.each do |raw_attribute|
      attribute_via_source = Attribute.find_by(
        name: raw_attribute.fetch("name"),
        base_friendly_id: raw_attribute.fetch("values_from"),
      )
      attribute_via_values_from = Attribute.find_by(friendly_id: raw_attribute.fetch("values_from"))

      assert_equal attribute_via_values_from.values.sort, attribute_via_source.values.sort
    end
  end

  # more fragile, but easier sanity check
  test "Snowboards category <sg-4-17-2-17> is fully imported and modeled correctly" do
    snowboard = Category.find("sg-4-17-2-17")

    assert_equal "Snowboards", snowboard.name
    assert_empty snowboard.children

    real_attribute_friendly_ids = snowboard.related_attributes.pluck(:friendly_id)
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
  test "Snowboard construction attribute <2894> is fully imported and modeled correctly" do
    snowboard_construction = Attribute.find(2894)

    assert_equal "Snowboard construction", snowboard_construction.name
    assert_equal "snowboard_construction", snowboard_construction.friendly_id

    real_value_friendly_ids = snowboard_construction.values.pluck(:friendly_id)
    assert_equal 4, real_value_friendly_ids.size
    assert_includes real_value_friendly_ids, "snowboard_construction__camber"
    assert_includes real_value_friendly_ids, "snowboard_construction__flat"
    assert_includes real_value_friendly_ids, "snowboard_construction__hybrid"
    assert_includes real_value_friendly_ids, "snowboard_construction__rocker"
  end

  test "MappingRules are fully imported from integrations/*/*/mappings/*_shopify.yml" do
    assert_equal @raw_mapping_rules_data.size,
      MappingRule.select(:integration_id, :from_shopify).distinct.to_a.count
    assert_equal @raw_mapping_rules_data.map { |raw| raw[:content]["rules"].count }.sum, MappingRule.count
  end

  test "MappingRule ↔ Product relationships are consistent with integrations/*/*/mappings/*_shopify.yml" do
    @raw_mapping_rules_data.each do |raw|
      from_shopify = File.basename(raw[:file_name], ".*").split("_")[0] == "from"
      integration_name = Pathname.new(raw[:file_name]).each_filename.to_a[-4]
      input_type = "ShopifyProduct"
      output_type = "#{integration_name.capitalize}Product"
      unless from_shopify
        input_type, output_type = output_type, input_type
      end
      raw[:content].fetch("rules").each do |raw_rule|
        input_id = Product.find_from_data(raw_rule["input"], type: input_type).id
        output_id = Product.find_from_data(raw_rule["output"], type: output_type).id

        assert_predicate MappingRule.find_by(input_id:, output_id:), :present?
      end
    end
  end
end
