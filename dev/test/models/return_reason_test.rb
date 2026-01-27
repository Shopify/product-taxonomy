# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ReturnReasonTest < TestCase
    setup do
      @return_reason = ReturnReason.new(
        id: 1,
        name: "Damaged",
        description: "Item was damaged",
        friendly_id: "damaged",
        handle: "damaged",
      )
    end

    test "load_from_source loads return reasons from deserialized YAML" do
      yaml_content = <<~YAML
        - id: 1
          name: Damaged
          description: Item was damaged
          friendly_id: damaged
          handle: damaged
        - id: 2
          name: Wrong Item
          description: Wrong item received
          friendly_id: wrong_item
          handle: wrong_item
      YAML

      ReturnReason.load_from_source(YAML.safe_load(yaml_content))

      assert_equal 2, ReturnReason.size

      damaged = ReturnReason.find_by(friendly_id: "damaged")
      assert_instance_of ReturnReason, damaged
      assert_equal 1, damaged.id
      assert_equal "Damaged", damaged.name
      assert_equal "Item was damaged", damaged.description
      assert_equal "damaged", damaged.friendly_id
      assert_equal "damaged", damaged.handle

      wrong_item = ReturnReason.find_by(friendly_id: "wrong_item")
      assert_instance_of ReturnReason, wrong_item
      assert_equal 2, wrong_item.id
      assert_equal "Wrong Item", wrong_item.name
      assert_equal "Wrong item received", wrong_item.description
      assert_equal "wrong_item", wrong_item.friendly_id
      assert_equal "wrong_item", wrong_item.handle
    end

    test "load_from_source raises an error if the source YAML does not follow the expected schema" do
      yaml_content = <<~YAML
        ---
        foo=bar
      YAML

      assert_raises(ArgumentError) { ReturnReason.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains incomplete return reasons" do
      yaml_content = <<~YAML
        - id: 1
          name: Damaged
      YAML

      assert_raises(ActiveModel::ValidationError) { ReturnReason.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains duplicate friendly IDs" do
      yaml_content = <<~YAML
        - id: 1
          name: Damaged
          description: Item was damaged
          friendly_id: damaged
          handle: damaged
        - id: 2
          name: Broken
          description: Item was broken
          friendly_id: damaged
          handle: broken
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        ReturnReason.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        friendly_id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises an error if the source data contains an invalid ID" do
      yaml_content = <<~YAML
        - id: foo
          name: Damaged
          description: Item was damaged
          friendly_id: damaged
          handle: damaged
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        ReturnReason.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        id: [{ error: :not_a_number, value: "foo" }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "gid returns the global ID of the return reason" do
      assert_equal "gid://shopify/ReturnReasonDefinition/1", @return_reason.gid
    end

    test "localized attributes are returned correctly" do
      stub_localizations

      return_reason = ReturnReason.new(
        id: 1,
        name: "Raw name",
        description: "Raw description",
        friendly_id: "damaged",
        handle: "damaged",
      )
      assert_equal "Raw name", return_reason.name
      assert_equal "Raw description", return_reason.description
      assert_equal "Raw name", return_reason.name(locale: "en")
      assert_equal "Raw description", return_reason.description(locale: "en")
      assert_equal "Nom en français", return_reason.name(locale: "fr")
      assert_equal "Description en français", return_reason.description(locale: "fr")
      assert_equal "Nombre en español", return_reason.name(locale: "es")
      assert_equal "Descripción en español", return_reason.description(locale: "es")
      assert_equal "Raw name", return_reason.name(locale: "cs") # fall back to en
      assert_equal "Raw description", return_reason.description(locale: "cs") # fall back to en
    end

    test "next_id returns 1 when there are no return reasons" do
      ReturnReason.reset
      assert_equal 1, ReturnReason.next_id
    end

    test "next_id returns max id + 1 when there are existing return reasons" do
      ReturnReason.reset
      ReturnReason.add(ReturnReason.new(
        id: 5,
        name: "Damaged",
        description: "Item was damaged",
        friendly_id: "damaged",
        handle: "damaged",
      ))
      ReturnReason.add(ReturnReason.new(
        id: 10,
        name: "Wrong Item",
        description: "Wrong item received",
        friendly_id: "wrong_item",
        handle: "wrong_item",
      ))
      ReturnReason.add(ReturnReason.new(
        id: 3,
        name: "Not as Described",
        description: "Item not as described",
        friendly_id: "not_as_described",
        handle: "not_as_described",
      ))

      assert_equal 11, ReturnReason.next_id
    end

    test "next_id returns correct value after return reasons have been reset" do
      ReturnReason.reset
      ReturnReason.add(ReturnReason.new(
        id: 5,
        name: "Damaged",
        description: "Item was damaged",
        friendly_id: "damaged",
        handle: "damaged",
      ))
      assert_equal 6, ReturnReason.next_id

      ReturnReason.reset
      assert_equal 1, ReturnReason.next_id

      ReturnReason.add(ReturnReason.new(
        id: 3,
        name: "Wrong Item",
        description: "Wrong item received",
        friendly_id: "wrong_item",
        handle: "wrong_item",
      ))
      assert_equal 4, ReturnReason.next_id
    end

    test "localizations_humanized_model_name returns return_reasons" do
      assert_equal "return_reasons", ReturnReason.localizations_humanized_model_name
    end

    private

    def stub_localizations
      fr_yaml = <<~YAML
        fr:
          return_reasons:
            damaged:
              name: "Nom en français"
              description: "Description en français"
      YAML
      es_yaml = <<~YAML
        es:
          return_reasons:
            damaged:
              name: "Nombre en español"
              description: "Descripción en español"
      YAML
      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "return_reasons", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))
    end
  end
end
