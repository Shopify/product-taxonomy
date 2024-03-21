# frozen_string_literal: true

require_relative "../test_helper"

class AllDataFilesImportTest < ActiveSupport::TestCase
  include Minitest::Hooks

  def before_all
    @raw_attributes_data = YAML.load_file("#{Application.root}/data/attributes/attributes.yml")
    DB::Seed.attributes_from(@raw_attributes_data)

    # Categories are only successfully parseable if attributes are already present
    category_files = Dir.glob("#{Application.root}/data/categories/*.yml")
    @raw_verticals_data = category_files.map { YAML.load_file(_1) }
    DB::Seed.categories_from(@raw_verticals_data)
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
end
