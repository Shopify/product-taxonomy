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

      values = Value.load_from_source(source_data: YAML.safe_load(yaml_content))

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

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains an invalid ID" do
      yaml_content = <<~YAML
        - id: foo
          name: Black
          friendly_id: color__black
          handle: color__black
      YAML

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
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

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
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

      assert_raises(ActiveModel::ValidationError) { Value.load_from_source(source_data: YAML.safe_load(yaml_content)) }
    end
  end
end
