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
        real_attribute = Property.find_by(friendly_id:)
        assert_includes real_category.properties, real_attribute
      end
    end
  end

  test "Attribute ↔ Value relationships are consistent with attributes.yml" do
    Property.all.each do |attribute|
      raw_attribute = @raw_attributes_data.find { _1.fetch("id") == attribute.id }
      raw_values = raw_attribute.fetch("values")
      real_values = attribute.property_values

      assert_equal raw_values.size, real_values.size
      raw_values.each do |raw_value|
        real_value = real_values.find { _1.id == raw_value.fetch("id") }
        assert_equal Serializers::Data::PropertyValueSerializer.deserialize(raw_value), real_value
      end
    end
  end

  # more fragile, but easier sanity check
  test "Snowboards category <sg-4-17-2-17> is fully imported and modeled correctly" do
    snowboard_id = "sg-4-17-2-17"
    raw_snowboard_category = @raw_verticals_data.flatten.find { _1.fetch("id") == snowboard_id }
    snowboard_category = Category.find(snowboard_id)

    assert_equal raw_snowboard_category.fetch("name"), snowboard_category.name
    assert_empty snowboard_category.children

    raw_snowboard_attributes = raw_snowboard_category.fetch("attributes").sort
    assert_equal raw_snowboard_attributes.size, snowboard_category.properties.size
    raw_snowboard_attributes
      .zip(snowboard_category.properties.reorder(:friendly_id))
      .each do |friendly_id, property|
        assert_equal friendly_id, property.friendly_id
      end
  end

  # more fragile, but easier sanity check
  test "Color attribute <1> is fully imported and modeled correctly" do
    color_id = 1
    raw_color_attribute = @raw_attributes_data.find { _1.fetch("id") == color_id }
    color_attribute = Property.find(color_id)

    assert_equal raw_color_attribute.fetch("name"), color_attribute.name

    raw_color_values = raw_color_attribute.fetch("values").sort_by { _1.fetch("id") }
    assert_equal raw_color_values.size, color_attribute.property_values.size
    raw_color_values
      .zip(color_attribute.property_values.reorder(:id))
      .each do |raw_value, value|
        assert_equal raw_value.fetch("id"), value.id
        assert_equal raw_value.fetch("name"), value.name
      end
  end
end
