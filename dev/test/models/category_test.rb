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
      root = Category.new(id: "aa", name: "Root")
      Category.add(root)
      child = Category.new(id: "aa", name: "Child")
      Category.add(child)
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

    test "to_json returns the JSON representation of the category for root node" do
      expected_json = {
        "id" => "gid://shopify/TaxonomyCategory/aa",
        "level" => 0,
        "name" => "Root",
        "full_name" => "Root",
        "parent_id" => nil,
        "attributes" => [],
        "children" => [{
          "id" => "gid://shopify/TaxonomyCategory/aa-1",
          "name" => "Child",
        }],
        "ancestors" => [],
      }
      assert_equal expected_json, @root.to_json
    end

    test "to_json returns the JSON representation of the category for child node" do
      expected_json = {
        "id" => "gid://shopify/TaxonomyCategory/aa-1",
        "level" => 1,
        "name" => "Child",
        "full_name" => "Root > Child",
        "parent_id" => "gid://shopify/TaxonomyCategory/aa",
        "attributes" => [],
        "children" => [{
          "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
          "name" => "Grandchild",
        }],
        "ancestors" => [{
          "id" => "gid://shopify/TaxonomyCategory/aa",
          "name" => "Root",
        }],
      }
      assert_equal expected_json, @child.to_json
    end

    test "to_json returns the JSON representation of the category for grandchild node" do
      expected_json = {
        "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
        "level" => 2,
        "name" => "Grandchild",
        "full_name" => "Root > Child > Grandchild",
        "parent_id" => "gid://shopify/TaxonomyCategory/aa-1",
        "attributes" => [],
        "children" => [],
        "ancestors" => [
          {
            "id" => "gid://shopify/TaxonomyCategory/aa-1",
            "name" => "Child",
          },
          {
            "id" => "gid://shopify/TaxonomyCategory/aa",
            "name" => "Root",
          },
        ],
      }
      assert_equal expected_json, @grandchild.to_json
    end

    test "to_json returns the localized JSON representation of the category for root node" do
      stub_localizations

      expected_json = {
        "id" => "gid://shopify/TaxonomyCategory/aa",
        "level" => 0,
        "name" => "Root en français",
        "full_name" => "Root en français",
        "parent_id" => nil,
        "attributes" => [],
        "children" => [{
          "id" => "gid://shopify/TaxonomyCategory/aa-1",
          "name" => "Child en français",
        }],
        "ancestors" => [],
      }
      assert_equal expected_json, @root.to_json(locale: "fr")
    end

    test "to_json returns the JSON representation of the category with children sorted by name" do
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Root
          children:
          - aa-1
          - aa-2
          - aa-3
          attributes: []
        - id: aa-1
          name: Cccc
          children: []
          attributes: []
        - id: aa-2
          name: Bbbb
          children: []
          attributes: []
        - id: aa-3
          name: Aaaa
          children: []
          attributes: []
      YAML

      Category.load_from_source(YAML.safe_load(yaml_content))

      assert_equal ["Aaaa", "Bbbb", "Cccc"], Category.verticals.first.to_json["children"].map { _1["name"] }
    end

    test "to_json returns the JSON representation of the category with attributes sorted by name" do
      value = Value.new(id: 1, name: "Black", friendly_id: "black", handle: "black")
      Value.add(value)
      attribute1 = Attribute.new(
        id: 1,
        name: "Aaaa",
        friendly_id: "aaaa",
        handle: "aaaa",
        description: "Aaaa",
        values: [value],
      )
      attribute2 = Attribute.new(
        id: 2,
        name: "Bbbb",
        friendly_id: "bbbb",
        handle: "bbbb",
        description: "Bbbb",
        values: [value],
      )
      attribute3 = Attribute.new(
        id: 3,
        name: "Cccc",
        friendly_id: "cccc",
        handle: "cccc",
        description: "Cccc",
        values: [value],
      )
      Attribute.add(attribute1)
      Attribute.add(attribute2)
      Attribute.add(attribute3)
      yaml_content = <<~YAML
        ---
        - id: aa
          name: Root
          attributes:
          - cccc
          - bbbb
          - aaaa
          children: []
      YAML

      Category.load_from_source(YAML.safe_load(yaml_content))
      assert_equal ["Aaaa", "Bbbb", "Cccc"], Category.verticals.first.to_json["attributes"].map { _1["name"] }
    end

    test "Category.to_json returns the JSON representation of all categories" do
      stub_localizations
      Category.stubs(:verticals).returns([@root])

      expected_json = {
        "version" => "1.0",
        "verticals" => [{
          "name" => "Root",
          "prefix" => "aa",
          "categories" => [
            {
              "id" => "gid://shopify/TaxonomyCategory/aa",
              "level" => 0,
              "name" => "Root",
              "full_name" => "Root",
              "parent_id" => nil,
              "attributes" => [],
              "children" => [{ "id" => "gid://shopify/TaxonomyCategory/aa-1", "name" => "Child" }],
              "ancestors" => [],
            },
            {
              "id" => "gid://shopify/TaxonomyCategory/aa-1",
              "level" => 1,
              "name" => "Child",
              "full_name" => "Root > Child",
              "parent_id" => "gid://shopify/TaxonomyCategory/aa",
              "attributes" => [],
              "children" => [{ "id" => "gid://shopify/TaxonomyCategory/aa-1-1", "name" => "Grandchild" }],
              "ancestors" => [{ "id" => "gid://shopify/TaxonomyCategory/aa", "name" => "Root" }],
            },
            {
              "id" => "gid://shopify/TaxonomyCategory/aa-1-1",
              "level" => 2,
              "name" => "Grandchild",
              "full_name" => "Root > Child > Grandchild",
              "parent_id" => "gid://shopify/TaxonomyCategory/aa-1",
              "attributes" => [],
              "children" => [],
              "ancestors" => [
                { "id" => "gid://shopify/TaxonomyCategory/aa-1", "name" => "Child" },
                { "id" => "gid://shopify/TaxonomyCategory/aa", "name" => "Root" },
              ],
            },
          ],
        }],
      }
      assert_equal expected_json, Category.to_json(version: "1.0")
    end

    test "to_txt returns the TXT representation of the category" do
      assert_equal "gid://shopify/TaxonomyCategory/aa : Root", @root.to_txt
    end

    test "to_txt returns the localized TXT representation of the category" do
      stub_localizations

      assert_equal "gid://shopify/TaxonomyCategory/aa : Root en français", @root.to_txt(locale: "fr")
    end

    test "Category.to_txt returns the TXT representation of all categories with correct padding" do
      stub_localizations
      Category.stubs(:verticals).returns([@root])
      Category.add(@root)
      Category.add(@child)
      Category.add(@grandchild)

      expected_txt = <<~TXT
        # Shopify Product Taxonomy - Categories: 1.0
        # Format: {GID} : {Ancestor name} > ... > {Category name}

        gid://shopify/TaxonomyCategory/aa     : Root
        gid://shopify/TaxonomyCategory/aa-1   : Root > Child
        gid://shopify/TaxonomyCategory/aa-1-1 : Root > Child > Grandchild
      TXT
      assert_equal expected_txt.strip, Category.to_txt(version: "1.0")
    end

    test "id_parts returns the parts of the ID" do
      assert_equal ["aa"], @root.id_parts
      assert_equal ["aa", 1], @child.id_parts
      assert_equal ["aa", 1, 1], @grandchild.id_parts
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
        .with(File.join(DATA_PATH, "localizations", "categories", "*.yml"))
        .returns(["fake/path/fr.yml", "fake/path/es.yml"])
      YAML.stubs(:safe_load_file).with("fake/path/fr.yml").returns(YAML.safe_load(fr_yaml))
      YAML.stubs(:safe_load_file).with("fake/path/es.yml").returns(YAML.safe_load(es_yaml))

      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "attributes", "*.yml"))
        .returns([])
      Dir.stubs(:glob)
        .with(File.join(DATA_PATH, "localizations", "values", "*.yml"))
        .returns([])
    end
  end
end
