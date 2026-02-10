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
      FileUtils.mkdir_p(File.expand_path("data/localizations/return_reasons", @tmp_base_path))
      ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))

      Command.any_instance.stubs(:load_taxonomy)
    end

    teardown do
      FileUtils.remove_entry(@tmp_base_path)
    end

    test "initialize sets targets to all permitted targets when not specified" do
      command = SyncEnLocalizationsCommand.new({})
      assert_equal ["categories", "attributes", "values", "return_reasons"], command.instance_variable_get(:@targets)
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
      mock_localizations = {
        "en" => {
          "categories" => {
            "test-1" => { "name" => "Test Category", "context" => "Test > Category" },
          },
        },
      }
      Serializers::Category::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "categories")
      command.execute

      expected_path = File.expand_path("data/localizations/categories/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          categories:
            test-1:
              # Test > Category
              name: Test Category
      YAML
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs attributes localizations" do
      mock_localizations = {
        "en" => {
          "attributes" => {
            "test-attr" => { "name" => "Test Attribute", "description" => "A test attribute" },
          },
        },
      }
      Serializers::Attribute::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "attributes")
      command.execute

      expected_path = File.expand_path("data/localizations/attributes/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          attributes:
            test-attr:
              name: Test Attribute
              description: A test attribute
      YAML
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs values localizations" do
      mock_localizations = {
        "en" => {
          "values" => {
            "test-value" => { "name" => "Test Value", "context" => "Test Attribute" },
          },
        },
      }
      Serializers::Value::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "values")
      command.execute

      expected_path = File.expand_path("data/localizations/values/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          values:
            test-value:
              # Test Attribute
              name: Test Value
      YAML
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs return_reasons localizations" do
      mock_localizations = {
        "en" => {
          "return_reasons" => {
            "damaged" => { "name" => "Damaged", "description" => "Item was damaged" },
          },
        },
      }
      Serializers::ReturnReason::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns(mock_localizations)

      command = SyncEnLocalizationsCommand.new(targets: "return_reasons")
      command.execute

      expected_path = File.expand_path("data/localizations/return_reasons/en.yml", @tmp_base_path)
      assert File.exist?(expected_path)
      expected_content = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          return_reasons:
            damaged:
              name: Damaged
              description: Item was damaged
      YAML
      assert_equal expected_content, File.read(expected_path)
    end

    test "execute syncs all targets when none specified" do
      Serializers::Category::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "en" => { "categories" => { "cat-1" => { "name" => "Category", "context" => "Category" } } } })
      Serializers::Attribute::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "en" => { "attributes" => { "attr-1" => { "name" => "Attribute", "description" => "Desc" } } } })
      Serializers::Value::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "en" => { "values" => { "val-1" => { "name" => "Value", "context" => "Attribute" } } } })
      Serializers::ReturnReason::Data::LocalizationsSerializer.stubs(:serialize_all)
        .returns({ "en" => { "return_reasons" => { "damaged" => { "name" => "Damaged", "description" => "Item was damaged" } } } })

      command = SyncEnLocalizationsCommand.new({})
      command.execute

      categories_path = File.expand_path("data/localizations/categories/en.yml", @tmp_base_path)
      attributes_path = File.expand_path("data/localizations/attributes/en.yml", @tmp_base_path)
      values_path = File.expand_path("data/localizations/values/en.yml", @tmp_base_path)
      return_reasons_path = File.expand_path("data/localizations/return_reasons/en.yml", @tmp_base_path)

      assert File.exist?(categories_path)
      assert File.exist?(attributes_path)
      assert File.exist?(values_path)
      assert File.exist?(return_reasons_path)

      expected_categories = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          categories:
            cat-1:
              # Category
              name: Category
      YAML
      expected_attributes = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          attributes:
            attr-1:
              name: Attribute
              description: Desc
      YAML
      expected_values = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          values:
            val-1:
              # Attribute
              name: Value
      YAML
      expected_return_reasons = <<~YAML
        # This file is auto-generated. Do not edit directly.
        ---
        en:
          return_reasons:
            damaged:
              name: Damaged
              description: Item was damaged
      YAML

      assert_equal expected_categories, File.read(categories_path)
      assert_equal expected_attributes, File.read(attributes_path)
      assert_equal expected_values, File.read(values_path)
      assert_equal expected_return_reasons, File.read(return_reasons_path)
    end

    test "serializers produce the expected structure for context extraction" do
      # This test validates the structure assumptions in extract_contexts.
      # If serializers change their output format, this test will fail.

      # Temporarily use real data path to load taxonomy
      ProductTaxonomy.unstub(:data_path)

      # Load real taxonomy data
      ProductTaxonomy::Loader.load(data_path: ProductTaxonomy.data_path)

      begin
        categories = Serializers::Category::Data::LocalizationsSerializer.serialize_all
        attributes = Serializers::Attribute::Data::LocalizationsSerializer.serialize_all
        values = Serializers::Value::Data::LocalizationsSerializer.serialize_all
        return_reasons = Serializers::ReturnReason::Data::LocalizationsSerializer.serialize_all

        [categories, attributes, values, return_reasons].each do |localizations|
          # Should be a hash with one locale key
          assert localizations.is_a?(Hash), "Expected localization to be a Hash"
          assert_equal 1, localizations.keys.size, "Expected exactly one locale key"

          locale, sections = localizations.first
          assert_equal "en", locale, "Expected locale to be 'en'"

          # Sections should be a hash with exactly ONE section
          # This is important because extract_contexts assumes no ID collisions across sections
          assert sections.is_a?(Hash), "Expected sections to be a Hash"
          assert_equal 1, sections.keys.size,
            "Expected exactly one section (to avoid entry ID collisions). Got: #{sections.keys.join(', ')}"

          # Verify no duplicate entry IDs across all sections (even though we expect only one section)
          # Redundant with single-section check above, but makes the extract_contexts assumption explicit.
          all_entry_ids = []
          sections.each do |_section_name, entries|
            all_entry_ids.concat(entries.keys)
          end
          duplicate_ids = all_entry_ids.group_by { |id| id }.select { |_id, occurrences| occurrences.size > 1 }.keys
          assert_empty duplicate_ids,
            "Found duplicate entry IDs across sections: #{duplicate_ids.join(', ')}"

          sections.each do |section_name, entries|
            # Each section should contain a hash of entries
            assert entries.is_a?(Hash), "Expected section '#{section_name}' to contain a Hash of entries"

            entries.each do |entry_id, data|
              # Each entry should be a hash with at least a 'name' field
              assert data.is_a?(Hash), "Expected entry '#{entry_id}' to be a Hash"
              assert data.key?("name"), "Expected entry '#{entry_id}' to have a 'name' field"

              # If 'context' exists, it should be a string
              if data.key?("context")
                assert data["context"].is_a?(String), "Expected 'context' in entry '#{entry_id}' to be a String"
              end
            end
          end
        end
      ensure
        # Clean up taxonomy data so it doesn't interfere with other tests
        Category.reset
        Attribute.reset
        Value.reset
        ReturnReason.reset
        # Re-stub data_path for other tests
        ProductTaxonomy.stubs(:data_path).returns(File.expand_path("data", @tmp_base_path))
      end
    end

  end
end
