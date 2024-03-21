# frozen_string_literal: true

require_relative "../test_helper"

class AllDataFilesImportTest < ActiveSupport::TestCase
  include Minitest::Hooks

  def before_all
    @raw_attributes_data = YAML.load_file("#{Application.root}/data/attributes/attributes.yml")
    DB::Seed.attributes_from(@raw_attributes_data)

    # this will be replaced by values.yml
    @unique_raw_values_data = @raw_attributes_data
      .flat_map { _1.fetch("values") }
      .uniq { _1.fetch("id") }

    # Categories are only successfully parseable if attributes are already present
    category_files = Dir.glob("#{Application.root}/data/categories/*.yml")
    @raw_verticals_data = category_files.map { YAML.load_file(_1) }
    DB::Seed.categories_from(@raw_verticals_data)
  end

  test "AttributeValues are correctly imported from attributes.yml" do
    assert_equal @unique_raw_values_data.size, PropertyValue.count
  end

  test "AttributeValues are consistent with attributes.yml" do
    @unique_raw_values_data.each do |raw_value|
      deserialized_value = Serializers::Data::PropertyValueSerializer.deserialize(raw_value)
      real_value = PropertyValue.find(raw_value.fetch("id"))

      assert_equal deserialized_value, real_value
    end
  end

  test "AttributeValues are all valid" do
    PropertyValue.all.each do |value|
      assert_predicate value, :valid?
    end
  end

  test "Attributes are correctly imported from attributes.yml" do
    assert_equal @raw_attributes_data.size, Property.count
  end

  test "Attributes are consistent with attributes.yml" do
    @raw_attributes_data.each do |raw_attribute|
      deserialized_attribute = Serializers::Data::PropertySerializer.deserialize(raw_attribute)
      real_attribute = Property.find(raw_attribute.fetch("id"))

      assert_equal deserialized_attribute, real_attribute
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
      deserialized_category = Serializers::Data::CategorySerializer.deserialize(raw_category)
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
      real_category = Category.find(raw_category.fetch("id"))
      raw_category.fetch("attributes").each do |friendly_id|
        property = Property.find_by(friendly_id:)
        assert_includes real_category.properties, property
      end
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml" do
    @raw_attributes_data.each do |raw_attribute|
      property = Property.find(raw_attribute.fetch("id"))
      raw_attribute.fetch("values").each do |raw_property_value|
        property_value = PropertyValue.find(raw_property_value.fetch("id"))
        assert_includes property.property_values, property_value
      end
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

    real_value_ids = snowboard_construction.property_value_ids
    assert_equal 4, real_value_ids.size
    assert_includes real_value_ids, 1363 # Flat
    assert_includes real_value_ids, 7083 # Hybrid
    assert_includes real_value_ids, 7236 # Camber
    assert_includes real_value_ids, 7237 # Rocker
  end
end
