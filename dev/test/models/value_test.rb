# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ValueTest < TestCase
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

    test "Value.sort_by_localized_name sorts values alphanumerically" do
      values = stub_color_values

      assert_equal ["Blue", "Green", "Red"], Value.sort_by_localized_name(values).map(&:name)
    end

    test "Value.sort_by_localized_name sorts non-English values alphanumerically" do
      values = stub_color_values

      sorted_values = Value.sort_by_localized_name(values, locale: "fr")

      assert_equal ["Bleu", "Rouge", "Vert"], sorted_values.map { _1.name(locale: "fr") }
    end

    test "Value.sort_by_localized_name sorts values with 'Other' at the end" do
      values = stub_pattern_values

      assert_equal ["Animal", "Striped", "Other"], Value.sort_by_localized_name(values).map(&:name)
    end

    test "Value.sort_by_localized_name sorts non-English values with 'Other' at the end" do
      values = stub_pattern_values

      sorted_values = Value.sort_by_localized_name(values, locale: "fr")

      assert_equal ["Animal", "Rayé", "Autre"], sorted_values.map { _1.name(locale: "fr") }
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
        .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
        .returns([])
    end

    def stub_color_values
      fr_yaml = <<~YAML
        fr:
          values:
            color__red:
              name: "Rouge"
            color__blue:
              name: "Bleu"
            color__green:
              name: "Vert"
      YAML
      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
        .returns(["fake/path/fr.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))

      [
        Value.new(id: 1, name: "Red", handle: "color__red", friendly_id: "color__red"),
        Value.new(id: 2, name: "Blue", handle: "color__blue", friendly_id: "color__blue"),
        Value.new(id: 3, name: "Green", handle: "color__green", friendly_id: "color__green"),
      ]
    end

    def stub_pattern_values
      fr_yaml = <<~YAML
        fr:
          values:
            pattern__animal:
              name: "Animal"
            pattern__striped:
              name: "Rayé"
            pattern__other:
              name: "Autre"
      YAML
      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
        .returns(["fake/path/fr.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))

      [
        Value.new(id: 1, name: "Animal", handle: "pattern__animal", friendly_id: "pattern__animal"),
        Value.new(id: 2, name: "Striped", handle: "pattern__striped", friendly_id: "pattern__striped"),
        Value.new(id: 3, name: "Other", handle: "pattern__other", friendly_id: "pattern__other"),
      ]
    end
  end
end
