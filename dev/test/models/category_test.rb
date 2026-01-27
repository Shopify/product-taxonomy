# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class CategoryTest < TestCase
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

    test "add_attribute adds multiple attributes to category's attributes" do
      category = Category.new(id: "aa", name: "Root")
      color_attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Defines the primary color",
        values: []
      )

      size_attribute = Attribute.new(
        id: 2,
        name: "Size",
        friendly_id: "size",
        handle: "size",
        description: "Defines the size",
        values: []
      )

      category.add_attribute(color_attribute)
      category.add_attribute(size_attribute)

      assert_includes category.attributes, color_attribute
      assert_includes category.attributes, size_attribute
      assert_equal 2, category.attributes.size
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
      error = assert_raises(ActiveModel::ValidationError) { category.validate!(:create) }
      expected_errors = {
        id: [{ error: :invalid, value: "foo" }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if name is blank" do
      category = Category.new(id: "aa", name: "")
      error = assert_raises(ActiveModel::ValidationError) { category.validate!(:create) }
      expected_errors = {
        name: [{ error: :blank }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if id depth doesn't match hierarchy level" do
      # A root category should have format "aa"
      parent = Category.new(id: "aa", name: "Root")
      category = Category.new(id: "aa-1-1", name: "Test", parent:)
      error = assert_raises(ActiveModel::ValidationError) { category.validate!(:category_tree_loaded) }
      expected_errors = {
        id: [{ error: :depth_mismatch }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error if child id doesn't start with parent id" do
      root = Category.new(id: "aa", name: "Root")
      child = Category.new(id: "bb-1", name: "Child")
      root.add_child(child)

      error = assert_raises(ActiveModel::ValidationError) { child.validate!(:category_tree_loaded) }
      expected_errors = {
        id: [{ error: :prefix_mismatch }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "raises validation error for duplicate id" do
      root = Category.new(id: "aa", name: "Root")
      Category.add(root)
      child = Category.new(id: "aa", name: "Child")
      Category.add(child)
      error = assert_raises(ActiveModel::ValidationError) { child.validate!(:create) }
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "validates correct id format examples" do
      assert_nothing_raised do
        Category.new(id: "aa", name: "Root").validate!(:create)
        root = Category.new(id: "bb", name: "Root")
        child = Category.new(id: "bb-1", name: "Child")
        root.add_child(child)
        child.validate!(:create)
        grandchild = Category.new(id: "bb-1-1", name: "Grandchild")
        child.add_child(grandchild)
        grandchild.validate!(:create)
      end
    end

    test "load_from_source loads categories from deserialized YAML" do
      value = Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
      Value.add(value)
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Defines the primary color or pattern, such as blue or striped",
        values: [value],
      )
      Attribute.add(attribute)
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

      Category.load_from_source(YAML.safe_load(yaml_content))

      aa_root = Category.verticals.first
      aa_clothing = aa_root.children.first
      assert_equal 2, Category.size
      assert_equal "aa", aa_root.id
      assert_equal "Apparel & Accessories", aa_root.name
      assert_equal [attribute], aa_root.attributes
      assert_equal 1, aa_root.children.size
      assert_equal "aa-1", aa_clothing.id
      assert_equal [attribute], aa_clothing.attributes
    end

    test "load_from_source preserves return_reasons order from YAML" do
      rr1 = ReturnReason.new(
        id: 1,
        name: "Zzz",
        description: "Zzz",
        friendly_id: "zzz",
        handle: "zzz",
      )
      rr2 = ReturnReason.new(
        id: 2,
        name: "Aaa",
        description: "Aaa",
        friendly_id: "aaa",
        handle: "aaa",
      )
      ReturnReason.add(rr1)
      ReturnReason.add(rr2)

      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          return_reasons:
          - zzz
          - aaa
      YAML

      Category.load_from_source(YAML.safe_load(yaml_content))

      actual = Category.verticals.first.return_reasons.map(&:friendly_id)
      assert_equal ["zzz", "aaa"], actual
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
        Category.load_from_source(YAML.safe_load(yaml_content))
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
        Category.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        children: [{ error: :not_found }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source raises validation error if return reason is not found" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Apparel & Accessories
          return_reasons:
          - foo ## This return reason does not exist
      YAML

      error = assert_raises(ActiveModel::ValidationError) do
        Category.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        return_reasons: [{ error: :not_found }],
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
        Category.load_from_source(YAML.safe_load(yaml_content))
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
        Category.load_from_source(YAML.safe_load(yaml_content))
      end
      expected_errors = {
        base: [{ error: :orphan }],
      }
      assert_equal expected_errors, error.model.errors.details
    end

    test "load_from_source loads categories with multiple paths from deserialized YAML" do
      value = Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
      Value.add(value)
      attribute = Attribute.new(
        id: 1,
        name: "Color",
        friendly_id: "color",
        handle: "color",
        description: "Defines the primary color or pattern, such as blue or striped",
        values: [value],
      )
      Attribute.add(attribute)
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

      Category.load_from_source(YAML.safe_load(yaml_content))

      aa_root = Category.verticals.first
      aa_clothing = aa_root.children.first
      bi_root = Category.verticals.second
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
      stub_localizations

      category = Category.new(id: "aa", name: "Raw name")
      assert_equal "Raw name", category.name
      assert_equal "Raw name", category.name(locale: "en")
      assert_equal "Root en français", category.name(locale: "fr")
      assert_equal "Root en español", category.name(locale: "es")
      assert_equal "Raw name", category.name(locale: "cs") # fall back to en
    end

    test "full_name returns the localized full name of the category" do
      stub_localizations

      assert_equal "Root en français", @root.full_name(locale: "fr")
      assert_equal "Root en français > Child en français", @child.full_name(locale: "fr")
      assert_equal "Root en français > Child en français > Grandchild en français", @grandchild.full_name(locale: "fr")
    end

    test "gid returns the GID of the category" do
      assert_equal "gid://shopify/TaxonomyCategory/aa", @root.gid
    end

    test "descendants returns the descendants of the category" do
      assert_equal [@child, @grandchild], @root.descendants
    end

    test "descendants_and_self returns the descendants and self of the category" do
      assert_equal [@root, @child, @grandchild], @root.descendants_and_self
    end

    test "id_parts returns the parts of the ID" do
      assert_equal ["aa"], @root.id_parts
      assert_equal ["aa", 1], @child.id_parts
      assert_equal ["aa", 1, 1], @grandchild.id_parts
    end

    test "next_child_id returns id-1 for category with no children" do
      category = Category.new(id: "aa", name: "Root")

      assert_equal "aa-1", category.next_child_id
    end

    test "next_child_id returns next sequential id based on largest child id" do
      root = Category.new(id: "aa", name: "Root")
      child1 = Category.new(id: "aa-1", name: "Child 1")
      child2 = Category.new(id: "aa-2", name: "Child 2")
      child3 = Category.new(id: "aa-5", name: "Child 3") # Note gap in sequence
      root.add_child(child1)
      root.add_child(child2)
      root.add_child(child3)

      assert_equal "aa-6", root.next_child_id
    end

    test "next_child_id ignores secondary children when determining next id" do
      root = Category.new(id: "aa", name: "Root")
      child = Category.new(id: "aa-1", name: "Child")
      secondary = Category.new(id: "bb-5", name: "Secondary")
      root.add_child(child)
      root.add_secondary_child(secondary)

      assert_equal "aa-2", root.next_child_id
    end

    private

    def stub_localizations
      fr_yaml = <<~YAML
        fr:
          categories:
            aa:
              name: "Root en français"
            aa-1:
              name: "Child en français"
            aa-1-1:
              name: "Grandchild en français"
      YAML
      es_yaml = <<~YAML
        es:
          categories:
            aa:
              name: "Root en español"
            aa-1:
              name: "Child en español"
            aa-1-1:
              name: "Grandchild en español"
      YAML
      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "categories", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "attributes", "*.yml"))
        .returns([])
      Dir.stubs(:glob)
        .with(File.join(ProductTaxonomy.data_path, "localizations", "values", "*.yml"))
        .returns([])
    end
  end
end
