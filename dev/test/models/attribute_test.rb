# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AttributeTest < ActiveSupport::TestCase
    test "load_from_source loads attributes from deserialized YAML" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        - id: 3
          name: Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: pattern
          handle: pattern
          values:
          - pattern__abstract
        extended_attributes:
        - id: 4
          name: Clothing Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: clothing_pattern
          handle: clothing_pattern
          values_from: pattern
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Abstract
          friendly_id: pattern__abstract
          handle: pattern__abstract
      YAML
      values_model_index = Value.load_from_source(source_data: YAML.safe_load(values_yaml_content))
      attributes = Attribute.load_from_source(
        source_data: YAML.safe_load(attributes_yaml_content),
        values: values_model_index.hashed_by(:friendly_id),
      ).hashed_by(:friendly_id)

      assert_equal 3, attributes.size

      color = attributes["color"]
      assert_instance_of Attribute, color
      assert_equal "color", color.handle
      assert_instance_of Array, color.values
      assert_instance_of Value, color.values.first
      assert_equal ["color__black"], color.values.map(&:friendly_id)

      pattern = attributes["pattern"]
      assert_instance_of Attribute, pattern
      assert_equal "pattern", pattern.handle
      assert_instance_of Array, pattern.values
      assert_instance_of Value, pattern.values.first
      assert_equal ["pattern__abstract"], pattern.values.map(&:friendly_id)

      clothing_pattern = attributes["clothing_pattern"]
      assert_instance_of ExtendedAttribute, clothing_pattern
      assert_equal "clothing_pattern", clothing_pattern.handle
      assert_instance_of Array, clothing_pattern.values
      assert_instance_of Value, clothing_pattern.values.first
      assert_equal ["pattern__abstract"], clothing_pattern.values.map(&:friendly_id)
    end

    test "load_from_source raises an error if the source YAML does not follow the expected schema" do
      yaml_content = <<~YAML
        ---
        foo=bar
      YAML

      assert_raises(ArgumentError) { Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {}) }
    end

    test "load_from_source raises an error if the source data contains incomplete attributes" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
        extended_attributes: []
      YAML

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {})
      end
    end

    test "load_from_source raises an error if the source data contains attributes with empty values" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values: []
        extended_attributes: []
      YAML

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {})
      end
    end

    test "load_from_source raises an error if the source data contains attributes with values that are not found" do
      yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - foo
        extended_attributes: []
      YAML

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {})
      end
    end

    test "load_from_source raises an error if the source data contains incomplete extended attributes" do
      yaml_content = <<~YAML
        ---
        base_attributes: []
        extended_attributes:
        - id: 2
          name: Clothing Color
          description: Defines the primary color or pattern, such as blue or striped
      YAML

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {})
      end
    end

    test "load_from_source raises an error if the source data contains extended attributes with values_from that is not found" do
      yaml_content = <<~YAML
        ---
        base_attributes: []
        extended_attributes:
        - id: 2
          name: Clothing Color
          description: Defines the primary color or pattern, such as blue or striped
          handle: clothing_color
          friendly_id: clothing_color
          values_from: foo
      YAML

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(source_data: YAML.safe_load(yaml_content), values: {})
      end
    end

    test "load_from_source raises an error if the source data contains duplicate friendly IDs" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: 1
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        - id: 2
          name: Pattern
          description: Describes the design or motif of a product, such as floral or striped
          friendly_id: color
          handle: pattern
          values:
          - pattern__abstract
        extended_attributes: []
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
        - id: 2
          name: Abstract
          friendly_id: pattern__abstract
          handle: pattern__abstract
      YAML
      values_model_index = Value.load_from_source(source_data: YAML.safe_load(values_yaml_content))

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(
          source_data: YAML.safe_load(attributes_yaml_content),
          values: values_model_index.hashed_by(:friendly_id),
        )
      end
    end

    test "load_from_source raises an error if the source data contains an invalid ID" do
      attributes_yaml_content = <<~YAML
        ---
        base_attributes:
        - id: foo
          name: Color
          description: Defines the primary color or pattern, such as blue or striped
          friendly_id: color
          handle: color
          values:
          - color__black
        extended_attributes: []
      YAML
      values_yaml_content = <<~YAML
        - id: 1
          name: Black
          friendly_id: color__black
          handle: color__black
      YAML
      values_model_index = Value.load_from_source(source_data: YAML.safe_load(values_yaml_content))

      assert_raises(ActiveModel::ValidationError) do
        Attribute.load_from_source(
          source_data: YAML.safe_load(attributes_yaml_content),
          values: values_model_index.hashed_by(:friendly_id),
        )
      end
    end
  end
end
