# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ValueTest < ActiveSupport::TestCase
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

      values = Value.load_from_source(source_data: YAML.safe_load(yaml_content)).hashed_by(:friendly_id)

      assert_equal 2, values.size

      black = values["color__black"]
      assert_instance_of Value, black
      assert_equal 1, black.id
      assert_equal "Black", black.name
      assert_equal "color__black", black.friendly_id
      assert_equal "color__black", black.handle

      blue = values["color__blue"]
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

      assert_raises(ArgumentError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains incomplete values" do
      yaml_content = <<~YAML
        - id: 1
          name: Black
      YAML

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
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
        Value.load_from_source(source_data: YAML.safe_load(yaml_content))
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
        Value.load_from_source(source_data: YAML.safe_load(yaml_content))
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
        Value.load_from_source(source_data: YAML.safe_load(yaml_content))
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
        Value.load_from_source(source_data: YAML.safe_load(yaml_content))
      end
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "localized attributes are returned correctly" do
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
      Dir.expects(:glob)
        .with(File.join(DATA_PATH, "localizations", "values", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.expects(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.expects(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      value = Value.new(id: 1, name: "Raw name", friendly_id: "color__black", handle: "color__black")
      assert_equal "Raw name", value.name
      assert_equal "Raw name", value.name(locale: "en")
      assert_equal "Nom en français", value.name(locale: "fr")
      assert_equal "Nombre en español", value.name(locale: "es")
      assert_equal "Raw name", value.name(locale: "cs") # fall back to en
    end
  end
end
