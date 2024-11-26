# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ValueTest < ActiveSupport::TestCase
    setup do
      @value = Value.new(id: 1, name: "Black", friendly_id: "color__black", handle: "color__black")
      @attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Color",
        values: [@value],
      )
      Attribute.add(@attribute)
    end

    test "load_from_source loads values from deserialized YAML" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Blue
          friendly_id: color__blue
          handle: color__blue
      YAML

      Value.load_from_source(YAML.safe_load(yaml_content))

      assert_equal 2, Value.size

      black = Value.find_by(friendly_id: "color__black")
      assert_instance_of Value, black
      assert_equal 1, black.id
      assert_equal "Black", black.name
      assert_equal "color__black", black.friendly_id
      assert_equal "color__black", black.handle

      blue = Value.find_by(friendly_id: "color__blue")
      assert_instance_of Value, blue
      assert_equal 2, blue.id
      assert_equal "Blue", blue.name
      assert_equal "color__blue", blue.friendly_id
      assert_equal "color__blue", blue.handle
    end

    test "load_from_source raises an error if the source YAML does not follow the expected schema" do
      yaml_content = <<~YAML
        ---
        foo=bar
      YAML

      assert_raises(ArgumentError) { Value.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains incomplete values" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
      YAML

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains duplicate friendly IDs" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Blue
          friendly_id: color__black
          handle: color__blue
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Value.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        friendly_id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains an invalid ID" do
      yaml_content = <<~YAML
        - id: foo
          name: Black
          friendly_id: color__black
          handle: color__black
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Value.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        id: [{ error: :not_a_number, value: "foo" }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains duplicate handles" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Blue
          friendly_id: color__blue
          handle: color__black
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Value.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        handle: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains duplicate IDs" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 1
          name: Blue
          friendly_id: color__blue
          handle: color__blue
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Value.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "localized attributes are returned correctly" do
      stub_localizations

      value = Value.new(id: 1, name: "Raw name", friendly_id: "color__black", handle: "color__black")
      assert_equal "Raw name", value.name
      assert_equal "Raw name", value.name(locale: "en")
      assert_equal "Nom en français", value.name(locale: "fr")
      assert_equal "Nombre en español", value.name(locale: "es")
      assert_equal "Raw name", value.name(locale: "cs") # fall back to en
    end

    test "primary_attribute returns the attribute for the value" do
      Attribute.reset
      value = Value.new(id: 1, name: "Black", friendly_id: "color__black", handle: "color__black")

      assert_nil value.primary_attribute

      attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Color",
        values: [value],
      )
      Attribute.add(attribute)

      assert_equal attribute, value.primary_attribute
    end

    test "primary_attribute returns nil if the attribute is not found" do
      Attribute.reset
      assert_nil @value.primary_attribute
    end

    test "full_name returns the name of the value and its primary attribute" do
      assert_equal "Black [Color]", @value.full_name
    end

    test "to_json returns the JSON representation of the value" do
      expected_json = {
        "id" => "gid://shopify/TaxonomyValue/1",
        "name" => "Black",
        "handle" => "color__black",
      }
      assert_equal expected_json, @value.to_json
    end

    test "to_json returns the localized JSON representation of the value" do
      stub_localizations

      expected_json = {
        "id" => "gid://shopify/TaxonomyValue/1",
        "name" => "Nom en français",
        "handle" => "color__black",
      }
      assert_equal expected_json, @value.to_json(locale: "fr")
    end

    test "Value.to_json returns the JSON representation of all values" do
      Value.add(@value)

      expected_json = {
        "version" => "1.0",
        "values" => [
          {
            "id" => "gid://shopify/TaxonomyValue/1",
            "name" => "Black",
            "handle" => "color__black",
          },
        ],
      }
      assert_equal expected_json, Value.to_json(version: "1.0")
    end

    test "to_txt returns the text representation of the value" do
      expected_txt = "gid://shopify/TaxonomyValue/1 : Black [Color]"
      assert_equal expected_txt, @value.to_txt
    end

    test "to_txt returns the localized text representation of the value" do
      stub_localizations

      expected_txt = "gid://shopify/TaxonomyValue/1 : Nom en français [Color]"
      assert_equal expected_txt, @value.to_txt(locale: "fr")
    end

    test "Value.to_txt returns the text representation of all values with correct padding" do
      value2 = Value.new(id: 123456, name: "Blue", friendly_id: "color__blue", handle: "color__blue")
      Value.add(@value)
      Value.add(value2)

      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Attribute Values: 1.0
        # Format: {GID} : {Value name} [{Attribute name}]

        gid://shopify/TaxonomyValue/1      : Black [Color]
        gid://shopify/TaxonomyValue/123456 : Blue [Color]
      TXT
      assert_equal expected_txt.strip, Value.to_txt(version: "1.0")
    end

    private

    def stub_localizations
      fr_yaml = <<~YAML
        fr:
          values:
            color__black:
              name: "Nom en français"
      YAML
      es_yaml = <<~YAML
        es:
          values:
            color__black:
              name: "Nombre en español"
      YAML
      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "values", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "attributes", "*.yml"))
        .returns([])
    end
  end
end
