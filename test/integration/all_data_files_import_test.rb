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

  test "data/attributes.yml has no empty value lists" do
    @raw_attributes_data.select { _1.key?("values") }.each do |raw_attribute|
      assert_predicate raw_attribute.fetch("values"), :present?
    end
  end

  test "data/attributes.yaml xor values or values_from" do
    @raw_attributes_data.each do |raw_attribute|
      assert raw_attribute.key?("values") ^ raw_attribute.key?("values_from")
    end
  end

  test "AttributeValues are correctly imported from values.yml" do
    assert_equal @raw_values_data.size, PropertyValue.count
  end

  test "AttributeValues are consistent with values.yml" do
    @raw_values_data.each do |raw_value|
      deserialized_value = SourceData::PropertyValueSerializer.deserialize(raw_value)
      real_value = PropertyValue.find(raw_value.fetch("id"))

      assert_equal deserialized_value, real_value
    end
  end

  test "AttributeValues are all valid" do
    PropertyValue.all.each do |value|
      assert_predicate value, :valid?
    end
  end

  test "AttributeValues all have a primary property" do
    PropertyValue.all.each do |value|
      assert_predicate value.primary_property, :present?, "Value #{value.friendly_id} has no primary property"
    end
  end

  test "Attributes are correctly imported from attributes.yml" do
    assert_equal @raw_attributes_data.size, Property.count
  end

  test "Attributes are consistent with attributes.yml" do
    @raw_attributes_data.each do |raw_attribute|
      deserialized_attribute = SourceData::PropertySerializer.deserialize(raw_attribute)
      real_attribute = Property.find(raw_attribute.fetch("id"))

      assert_equal deserialized_attribute, real_attribute
    end
  end

  test "Attributes have primary properties if they inherit values" do
    @raw_attributes_data.each do |raw_attribute|
      next unless raw_attribute.key?("values_from")

      real_attribute = Property.find(raw_attribute.fetch("id"))
      real_parent_property = Property.find_by!(friendly_id: raw_attribute.fetch("values_from"))

      assert_equal real_parent_property, real_attribute.parent
    end
  end

  test "Attributes are all valid" do
    Property.all.each do |attribute|
      assert_predicate attribute, :valid?
    end
  end

  test "Categories are fully imported from categories/*.yml" do
    assert_equal @raw_verticals_data.size, Category.verticals.count
    assert_equal @raw_verticals_data.map(&:size).sum, Category.count
  end

  test "Categories are consistent with categories/*.yml" do
    @raw_verticals_data.flatten.each do |raw_category|
      deserialized_category = SourceData::CategorySerializer.deserialize(raw_category)
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
      properties_via_raw_category_id = Category.find(raw_category.fetch("id")).properties
      properties_via_raw_attributes = raw_category.fetch("attributes").map { Property.find_by(friendly_id: _1) }

      assert_equal properties_via_raw_attributes.sort, properties_via_raw_category_id.sort
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml when values are listed" do
    @raw_attributes_data.select { _1.key?("values") }.each do |raw_attribute|
      values_via_raw_id = Property.find(raw_attribute.fetch("id")).property_values
      values_via_raw_values = raw_attribute.fetch("values").map { PropertyValue.find_by(friendly_id: _1) }

      assert_equal values_via_raw_values.sort, values_via_raw_id.sort
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml when values are inherited" do
    @raw_attributes_data.select { _1.key?("values_from") }.each do |raw_attribute|
      values_via_raw_id = Property.find(raw_attribute.fetch("id")).property_values
      values_via_raw_values_from = Property.find_by(friendly_id: raw_attribute.fetch("values_from")).property_values

      assert_equal values_via_raw_values_from.sort, values_via_raw_id.sort
    end
  end

  # more fragile, but easier sanity check
  test "Snowboards category <sg-4-17-2-17> is fully imported and modeled correctly" do
    snowboard = Category.find("sg-4-17-2-17")

    assert_equal "Snowboards", snowboard.name
    assert_empty snowboard.children

    real_property_friendly_ids = snowboard.properties.pluck(:friendly_id)
    assert_equal 8, real_property_friendly_ids.size
    assert_includes real_property_friendly_ids, "age_group"
    assert_includes real_property_friendly_ids, "color"
    assert_includes real_property_friendly_ids, "pattern"
    assert_includes real_property_friendly_ids, "recommended_skill_level"
    assert_includes real_property_friendly_ids, "snowboard_design"
    assert_includes real_property_friendly_ids, "snowboarding_style"
    assert_includes real_property_friendly_ids, "target_gender"
    assert_includes real_property_friendly_ids, "snowboard_construction"
  end

  # more fragile, but easier sanity check
  test "Snowboard construction attribute <2894> is fully imported and modeled correctly" do
    snowboard_construction = Property.find(2894)

    assert_equal "Snowboard construction", snowboard_construction.name
    assert_equal "snowboard_construction", snowboard_construction.friendly_id

    real_value_friendly_ids = snowboard_construction.property_values.pluck(:friendly_id)
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
        deserialized_input_product = SourceData::ProductSerializer.deserialize(raw_rule.fetch("input"), input_type)
        deserialized_output_product = SourceData::ProductSerializer.deserialize(raw_rule.fetch("output"), output_type)
        input_id = Product.find_by(type: input_type, payload: deserialized_input_product.payload).id
        output_id = Product.find_by(type: output_type, payload: deserialized_output_product.payload).id
        assert_predicate MappingRule.find_by(input_id: input_id, output_id: output_id), :present?
      end
    end
  end
end
