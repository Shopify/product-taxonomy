# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class CategoryTest < ActiveSupport::TestCase
    setup do
      @root = Category.new(id: "aa", name: "Root")
      @child = Category.new(id: "aa-1", name: "Child")
      @root.add_child(@child)
      @grandchild = Category.new(id: "aa-1-1", name: "Grandchild")
      @child.add_child(@grandchild)
    end

    test "add_child sets parent-child relationship" do
      root = Category.new(id: "aa", name: "Root")
      child = Category.new(id: "aa-1", name: "Child")
      root.add_child(child)
      assert_includes root.children, child
      assert_equal root, child.parent
    end

    test "add_secondary_child sets secondary relationships" do
      root = Category.new(id: "aa", name: "Root")
      root2 = Category.new(id: "bb", name: "Root2")
      child = Category.new(id: "aa-1", name: "Child")
      root.add_secondary_child(child)
      root2.add_secondary_child(child)
      assert_includes root.secondary_children, child
      assert_includes root2.secondary_children, child
      assert_equal [root, root2], child.secondary_parents
    end

    test "root? is true for root node" do
      assert @root.root?
    end

    test "root? is false for child node" do
      refute @child.root?
    end

    test "leaf? is true for node without children" do
      assert @grandchild.leaf?
    end

    test "leaf? is true for node with only secondary children" do
      @grandchild.add_secondary_child(@child)
      assert @grandchild.leaf?
    end

    test "leaf? is false for node with children" do
      refute @root.leaf?
    end

    test "level is 0 for root node" do
      assert_equal 0, @root.level
    end

    test "level is 1 for child node" do
      assert_equal 1, @child.level
    end

    test "level is 2 for grandchild node" do
      assert_equal 2, @grandchild.level
    end

    test "ancestors is empty for root node" do
      assert_empty @root.ancestors
    end

    test "ancestors contains [root] for child node" do
      assert_equal [@root], @child.ancestors
    end

    test "ancestors contains [parent, root] for grandchild node" do
      assert_equal [@child, @root], @grandchild.ancestors
    end

    test "root returns self for root node" do
      assert_equal @root, @root.root
    end

    test "root returns root node for child node" do
      assert_equal @root, @child.root
    end

    test "root returns root node for grandchild node" do
      assert_equal @root, @grandchild.root
    end

    test "full_name returns name for root node" do
      assert_equal "Root", @root.full_name
    end

    test "full_name returns parent > child for child node" do
      assert_equal "Root > Child", @child.full_name
    end

    test "full_name returns full path for grandchild node" do
      assert_equal "Root > Child > Grandchild", @grandchild.full_name
    end

    test "descendant_of? is true for child of root" do
      assert @child.descendant_of?(@root)
    end

    test "descendant_of? is true for grandchild of root" do
      assert @grandchild.descendant_of?(@root)
    end

    test "descendant_of? is true for child of parent" do
      assert @grandchild.descendant_of?(@child)
    end

    test "descendant_of? is false for parent of child" do
      refute @child.descendant_of?(@grandchild)
    end

    test "descendant_of? is false for root of child" do
      refute @root.descendant_of?(@child)
    end

    test "raises validation error if id is invalid" do
      category = Category.new(id: "foo", name: "Test")
      error = assert_raises(ActiveModel::ValidationError) { category.validate! }
      expected_errors = {
        id: [{ error: :invalid, value: "foo" }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if name is blank" do
      category = Category.new(id: "aa", name: "")
      error = assert_raises(ActiveModel::ValidationError) { category.validate! }
      expected_errors = {
        name: [{ error: :blank }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if id depth doesn't match hierarchy level" do
      # A root category should have format "aa"
      parent = Category.new(id: "aa", name: "Root")
      category = Category.new(id: "aa-1-1", name: "Test", parent:)
      error = assert_raises(ActiveModel::ValidationError) { category.validate! }
      expected_errors = {
        id: [{ error: :depth_mismatch }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if child id doesn't start with parent id" do
      root = Category.new(id: "aa", name: "Root")
      child = Category.new(id: "bb-1", name: "Child")
      root.add_child(child)

      error = assert_raises(ActiveModel::ValidationError) { child.validate! }
      expected_errors = {
        id: [{ error: :prefix_mismatch }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error for duplicate id" do
      uniqueness_context = ModelIndex.new(Category)
      root = Category.new(id: "aa", name: "Root", uniqueness_context:)
      uniqueness_context.add(root)
      child = Category.new(id: "aa", name: "Child", uniqueness_context:)
      uniqueness_context.add(child)
      error = assert_raises(ActiveModel::ValidationError) { child.validate! }
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "validates correct id format examples" do
      assert_nothing_raised do
        Category.new(id: "aa", name: "Root").validate!
        root = Category.new(id: "bb", name: "Root")
        child = Category.new(id: "bb-1", name: "Child")
        root.add_child(child)
        child.validate!
        grandchild = Category.new(id: "bb-1-1", name: "Grandchild")
        child.add_child(grandchild)
        grandchild.validate!
      end
    end

    test "load_from_source loads categories from deserialized YAML" do
      value = Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Defines the primary color or pattern, such as blue or striped",
        values: [value],
      )
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          children:
          - aa-1
          attributes:
          - color
        - id: aa-1
          name: Clothing
          children: []
          attributes:
          - color
      YAML

      categories = Category.load_from_source(
        source_data: YAML.safe_load(yaml_content),
        attributes: { "color" => attribute },
      )

      assert_equal 1, categories.size
      assert_equal "aa", categories.first.id
      assert_equal "Apparel & Accessories", categories.first.name
      assert_equal [attribute], categories.first.attributes
      assert_equal 1, categories.first.children.size
      assert_equal "aa-1", categories.first.children.first.id
      assert_equal [attribute], categories.first.children.first.attributes
    end

    test "load_from_source raises validation error if attribute is not found" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          children: []
          attributes:
          - foo
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Category.load_from_source(source_data: YAML.safe_load(yaml_content), attributes: {})
      end
      expected_errors = {
        attributes: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises validation error if child is not found" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          children:
          - aa-1
          attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Category.load_from_source(source_data: YAML.safe_load(yaml_content), attributes: {})
      end
      expected_errors = {
        children: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises validation error if secondary child is not found" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          secondary_children:
          - aa-1
          attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Category.load_from_source(source_data: YAML.safe_load(yaml_content), attributes: {})
      end
      expected_errors = {
        secondary_children: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises validation error if category is orphaned" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          attributes: []
          children: [] # aa-1 is missing
        - id: aa-1
          name: Clothing
          attributes: []
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Category.load_from_source(source_data: YAML.safe_load(yaml_content), attributes: {})
      end
      expected_errors = {
        base: [{ error: :orphan }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source loads categories with multiple paths from deserialized YAML" do
      value = Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Defines the primary color or pattern, such as blue or striped",
        values: [value],
      )
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          children:
          - aa-1
          attributes:
          - color
        - id: aa-1
          name: Clothing
          children: []
          secondary_children:
          - bi-19-10
        - id: bi
          name: Business & Industrial
          children:
          - bi-19
          attributes:
          - color
        - id: bi-19
          name: Medical
          children:
          - bi-19-10
          attributes:
          - color
        - id: bi-19-10
          name: Scrubs
          children: []
          attributes:
          - color
      YAML

      categories = Category.load_from_source(
        source_data: YAML.safe_load(yaml_content),
        attributes: { "color" => attribute },
      )

      aa_root = categories.first
      aa_clothing = aa_root.children.first
      bi_root = categories.second
      bi_medical = bi_root.children.first
      bi_scrubs = bi_medical.children.first

      assert_equal "aa", aa_root.id
      assert_equal "aa-1", aa_clothing.id
      assert_equal "bi", bi_root.id
      assert_equal "bi-19", bi_medical.id
      assert_equal "bi-19-10", bi_scrubs.id
      assert_equal bi_scrubs, aa_clothing.secondary_children.first
      assert_equal bi_medical, bi_scrubs.parent
      assert_equal aa_clothing, bi_scrubs.secondary_parents.first
    end

    test "localized attributes are returned correctly" do
      fr_yaml = <<~YAML
        fr:
          categories:
            aa:
              name: "Nom en français"
      YAML
      es_yaml = <<~YAML
        es:
          categories:
            aa:
              name: "Nombre en español"
      YAML
      Dir.expects(:glob)
        .with(File.join(DATA_PATH, "localizations", "categories", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.expects(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.expects(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      category = Category.new(id: "aa", name: "Raw name")
      assert_equal "Raw name", category.name
      assert_equal "Raw name", category.name(locale: "en")
      assert_equal "Nom en français", category.name(locale: "fr")
      assert_equal "Nombre en español", category.name(locale: "es")
      assert_equal "Raw name", category.name(locale: "cs") # fall back to en
    end
  end
end
