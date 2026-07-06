# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class DisclosureTest < TestCase
    test "load_from_source loads a hierarchy of disclosures from deserialized YAML" do
      Disclosure.load_from_source(YAML.safe_load(valid_source))

      assert_equal 3, Disclosure.size

      group = Disclosure.find_by(public_id: "choking_hazard")
      assert_instance_of Disclosure, group
      assert_equal 1, group.id
      assert_nil group.parent_id
      assert group.root?
      refute group.leaf?
      assert_equal [2, 3], group.children.map(&:id).sort

      leaf = Disclosure.find_by(public_id: "us-cpsc-choking_small_parts")
      assert_equal 2, leaf.id
      assert_equal group, leaf.parent
      assert leaf.leaf?
      assert_equal ["US"], leaf.jurisdictions
      assert_equal({ "surfaces" => ["product_page"] }, leaf.display_preferences)
    end

    test "load_from_source raises an error if the source YAML does not follow the expected schema" do
      yaml_content = <<~YAML
        ---
        foo=bar
      YAML

      assert_raises(ArgumentError) { Disclosure.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if a disclosure is missing required fields" do
      yaml_content = <<~YAML
        - id: 1
          public_id: choking_hazard
      YAML

      assert_raises(ActiveModel::ValidationError) { Disclosure.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains duplicate public IDs" do
      yaml_content = <<~YAML
        - id: 1
          public_id: choking_hazard
          name: Choking hazards
          internal_label: Choking hazards
        - id: 2
          public_id: choking_hazard
          name: Duplicate
          internal_label: Duplicate
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_equal [{ error: :taken }], error.model.errors.details[:public_id]
    end

    test "load_from_source raises an error if an id is not an integer" do
      yaml_content = <<~YAML
        - id: foo
          public_id: choking_hazard
          name: Choking hazards
          internal_label: Choking hazards
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_equal [{ error: :not_a_number, value: "foo" }], error.model.errors.details[:id]
    end

    test "gid returns the global ID of the disclosure" do
      disclosure = Disclosure.new(id: 2, public_id: "x", name: "X", internal_label: "X")
      assert_equal "gid://shopify/TaxonomyDisclosure/2", disclosure.gid
    end

    test "taxonomy_loaded validation passes for a well-formed hierarchy" do
      Disclosure.load_from_source(YAML.safe_load(valid_source))

      Disclosure.all.each { |disclosure| assert disclosure.valid?(:taxonomy_loaded), disclosure.errors.full_messages.to_s }
    end

    test "taxonomy_loaded validation fails when a leaf is missing jurisdictions or display preferences" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - id: 1
          public_id: group
          name: Group
          internal_label: Group
        - id: 2
          public_id: leaf
          parent_id: 1
          name: Leaf
          internal_label: Leaf
      YAML

      leaf = Disclosure.find_by(public_id: "leaf")
      refute leaf.valid?(:taxonomy_loaded)
      assert_includes leaf.errors.attribute_names, :jurisdictions
      assert_includes leaf.errors.attribute_names, :display_preferences
    end

    test "taxonomy_loaded validation fails when a grouping node defines jurisdictions" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - id: 1
          public_id: group
          name: Group
          internal_label: Group
          jurisdictions:
          - US
        - id: 2
          public_id: leaf
          parent_id: 1
          name: Leaf
          internal_label: Leaf
          jurisdictions:
          - US
          display_preferences:
            surfaces:
            - product_page
      YAML

      group = Disclosure.find_by(public_id: "group")
      refute group.valid?(:taxonomy_loaded)
      assert_includes group.errors.attribute_names, :jurisdictions
    end

    test "taxonomy_loaded validation fails on an unknown display surface" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - id: 1
          public_id: group
          name: Group
          internal_label: Group
        - id: 2
          public_id: leaf
          parent_id: 1
          name: Leaf
          internal_label: Leaf
          jurisdictions:
          - US
          display_preferences:
            surfaces:
            - checkout_confirmation
      YAML

      leaf = Disclosure.find_by(public_id: "leaf")
      refute leaf.valid?(:taxonomy_loaded)
      assert_includes leaf.errors.attribute_names, :display_preferences
    end

    test "taxonomy_loaded validation fails when parent_id references a missing disclosure" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - id: 2
          public_id: leaf
          parent_id: 99
          name: Leaf
          internal_label: Leaf
          jurisdictions:
          - US
          display_preferences:
            surfaces:
            - product_page
      YAML

      leaf = Disclosure.find_by(public_id: "leaf")
      refute leaf.valid?(:taxonomy_loaded)
      assert_includes leaf.errors.attribute_names, :parent_id
    end

    private

    def valid_source
      <<~YAML
        - id: 1
          public_id: choking_hazard
          parent_id:
          name: Choking hazards
          internal_label: Choking hazards
          description: Choking and suffocation hazards for children
          disclosure_attributes: []
          disclosure_attribute_values: []
        - id: 2
          public_id: us-cpsc-choking_small_parts
          parent_id: 1
          name: Choking Hazard — Small Parts (US)
          internal_label: Choking Hazard — Small Parts (US)
          jurisdictions:
          - US
          legal_citation: 16 CFR 1501
          display_preferences:
            surfaces:
            - product_page
          title: "Choking Hazard: Small Parts"
          content: Not for children under 3 years.
        - id: 3
          public_id: us-cpsc-choking_balloons
          parent_id: 1
          name: Choking Hazard — Balloons (US)
          internal_label: Choking Hazard — Balloons (US)
          jurisdictions:
          - US
          legal_citation: 16 CFR 1500.19
          display_preferences:
            surfaces:
            - product_page
          title: Balloon Choking Hazard
          content: Adult supervision required.
      YAML
    end
  end
end
