# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class DisclosureTest < TestCase
    test "load_from_source loads a hierarchy of disclosures from deserialized YAML" do
      Disclosure.load_from_source(YAML.safe_load(valid_source))

      assert_equal 3, Disclosure.size

      group = Disclosure.find_by(public_id: "choking_hazard")
      assert_instance_of Disclosure, group
      assert_nil group.parent_public_id
      assert group.root?
      refute group.leaf?
      assert_equal ["us-cpsc-choking_balloons", "us-cpsc-choking_small_parts"], group.children.map(&:public_id).sort

      leaf = Disclosure.find_by(public_id: "us-cpsc-choking_small_parts")
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
        - public_id: choking_hazard
      YAML

      assert_raises(ActiveModel::ValidationError) { Disclosure.load_from_source(YAML.safe_load(yaml_content)) }
    end

    test "load_from_source raises an error if the source data contains duplicate public IDs" do
      yaml_content = <<~YAML
        - public_id: choking_hazard
          name: Choking hazards
          internal_label: Choking hazards
        - public_id: choking_hazard
          name: Duplicate
          internal_label: Duplicate
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_equal [{ error: :taken }], error.model.errors.details[:public_id]
    end

    test "gid returns the global ID of the disclosure" do
      disclosure = Disclosure.new(public_id: "us-cpsc-choking_small_parts", name: "X", internal_label: "X")
      assert_equal "gid://shopify/TaxonomyDisclosure/us-cpsc-choking_small_parts", disclosure.gid
    end

    test "taxonomy_loaded validation passes for a well-formed hierarchy" do
      Disclosure.load_from_source(YAML.safe_load(valid_source))

      Disclosure.all.each { |disclosure| assert disclosure.valid?(:taxonomy_loaded), disclosure.errors.full_messages.to_s }
    end

    test "taxonomy_loaded validation fails when a leaf is missing jurisdictions or display preferences" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - public_id: group
          name: Group
          internal_label: Group
        - public_id: leaf
          parent_public_id: group
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
        - public_id: group
          name: Group
          internal_label: Group
          jurisdictions:
          - US
        - public_id: leaf
          parent_public_id: group
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
        - public_id: group
          name: Group
          internal_label: Group
        - public_id: leaf
          parent_public_id: group
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

    test "taxonomy_loaded validation fails when parent_public_id references a missing disclosure" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - public_id: leaf
          parent_public_id: missing_group
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
      assert_includes leaf.errors.attribute_names, :parent_public_id
    end

    test "load_from_source raises an error if public_id is not a valid slug" do
      yaml_content = <<~YAML
        - public_id: Not A Slug
          name: Choking hazards
          internal_label: Choking hazards
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_includes error.model.errors.attribute_names, :public_id
    end

    test "load_from_source raises an error if a field has the wrong type" do
      yaml_content = <<~YAML
        - public_id: leaf
          name: Leaf
          internal_label: Leaf
          jurisdictions: US
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_equal [{ error: :invalid }], error.model.errors.details[:jurisdictions]
    end

    test "load_from_source raises an error if a disclosure is its own parent" do
      yaml_content = <<~YAML
        - public_id: loop
          parent_public_id: loop
          name: Loop
          internal_label: Loop
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Disclosure.load_from_source(YAML.safe_load(yaml_content))
      end
      assert_includes error.model.errors.attribute_names, :parent_public_id
    end

    test "taxonomy_loaded validation fails when the hierarchy is more than two levels deep" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - public_id: root
          name: Root
          internal_label: Root
        - public_id: mid
          parent_public_id: root
          name: Mid
          internal_label: Mid
        - public_id: leaf
          parent_public_id: mid
          name: Leaf
          internal_label: Leaf
          jurisdictions:
          - US
          legal_citation: X
          title: T
          content: C
          source: S
          display_preferences:
            surfaces:
            - product_page
      YAML

      leaf = Disclosure.find_by(public_id: "leaf")
      refute leaf.valid?(:taxonomy_loaded)
      assert_includes leaf.errors.attribute_names, :parent_public_id
    end

    test "taxonomy_loaded validation fails when the hierarchy contains a cycle" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - public_id: a
          parent_public_id: b
          name: A
          internal_label: A
        - public_id: b
          parent_public_id: a
          name: B
          internal_label: B
      YAML

      node = Disclosure.find_by(public_id: "a")
      refute node.valid?(:taxonomy_loaded)
      assert_includes node.errors.attribute_names, :parent_public_id
    end

    test "taxonomy_loaded validation fails when a leaf is missing required legal fields" do
      Disclosure.load_from_source(YAML.safe_load(<<~YAML))
        - public_id: group
          name: Group
          internal_label: Group
        - public_id: leaf
          parent_public_id: group
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
      assert_includes leaf.errors.attribute_names, :title
      assert_includes leaf.errors.attribute_names, :content
      assert_includes leaf.errors.attribute_names, :legal_citation
      assert_includes leaf.errors.attribute_names, :source
    end

    test "localized attributes fall back to the raw value for the en locale" do
      Disclosure.load_from_source(YAML.safe_load(valid_source))

      leaf = Disclosure.find_by(public_id: "us-cpsc-choking_small_parts")
      assert_equal "Choking Hazard: Small Parts", leaf.title
      assert_equal "Choking Hazard: Small Parts", leaf.title(locale: "en")
    end

    private

    def valid_source
      <<~YAML
        - public_id: choking_hazard
          parent_public_id:
          name: Choking hazards
          internal_label: Choking hazards
          description: Choking and suffocation hazards for children
          disclosure_attributes: []
          disclosure_attribute_values: []
        - public_id: us-cpsc-choking_small_parts
          parent_public_id: choking_hazard
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
          source: https://www.ecfr.gov/current/title-16/part-1501
        - public_id: us-cpsc-choking_balloons
          parent_public_id: choking_hazard
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
          source: https://www.ecfr.gov/current/title-16/section-1500.19
      YAML
    end
  end
end
