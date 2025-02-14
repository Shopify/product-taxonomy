# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module ProductTaxonomy
  class SyncEnLocalizationsCommandTest < TestCase
    setup do
      @tmp_base_path = Dir.mktmpdir
      @real_base_path = File.expand_path("..", ProductTaxonomy.data_path)

      FileUtils.mkdir_p(File.expand_path("data/localizations/categories", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/localizations/attributes", @tmp_base_path))
      FileUtils.mkdir_p(File.expand_path("data/localizations/values", @tmp_base_path))
      ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))

      Command.any_instance.stubs(:load_taxonomy)
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets targets to all permitted targets when not specified" do
      command = SyncEnLocalizationsCommand.new({})
      assert_equal ["categories", "attributes", "values"], command.instance_variable_get(:@targets)
    end

    test "initialize accepts custom targets" do
      command = SyncEnLocalizationsCommand.new(targets: "categories,attributes")
      assert_equal ["categories", "attributes"], command.instance_variable_get(:@targets)
    end

    test "initialize raises error for invalid target" do
      assert_raises(RuntimeError) do
        SyncEnLocalizationsCommand.new(targets: "invalid,categories")
      end
    end

    test "execute syncs categories localizations" do
      mock_localizations = { "test" => "data" }
      Serializers::Category::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "categories")
      command.execute

      expected_path = File.expand_path("data/localizations/categories/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = "# This file is auto-generated. Do not edit directly.\n---\ntest: data\n"
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs attributes localizations" do
      mock_localizations = { "test" => "attribute_data" }
      Serializers::Attribute::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "attributes")
      command.execute

      expected_path = File.expand_path("data/localizations/attributes/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = "# This file is auto-generated. Do not edit directly.\n---\ntest: attribute_data\n"
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs values localizations" do
      mock_localizations = { "test" => "value_data" }
      Serializers::Value::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "values")
      command.execute

      expected_path = File.expand_path("data/localizations/values/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = "# This file is auto-generated. Do not edit directly.\n---\ntest: value_data\n"
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs all targets when none specified" do
      Serializers::Category::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "category" => "data" })
      Serializers::Attribute::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "attribute" => "data" })
      Serializers::Value::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "value" => "data" })

      command = SyncEnLocalizationsCommand.new({})
      command.execute

      categories_path = File.expand_path("data/localizations/categories/en.yml", @tmp_base_path)
      attributes_path = File.expand_path("data/localizations/attributes/en.yml", @tmp_base_path)
      values_path = File.expand_path("data/localizations/values/en.yml", @tmp_base_path)

      assert File.exist?(categories_path)
      assert File.exist?(attributes_path)
      assert File.exist?(values_path)

      expected_categories = "# This file is auto-generated. Do not edit directly.\n---\ncategory: data\n"
      expected_attributes = "# This file is auto-generated. Do not edit directly.\n---\nattribute: data\n"
      expected_values = "# This file is auto-generated. Do not edit directly.\n---\nvalue: data\n"

      assert_equal expected_categories, File.read(categories_path)
      assert_equal expected_attributes, File.read(attributes_path)
      assert_equal expected_values, File.read(values_path)
    end
  end
end
