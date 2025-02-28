# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddAttributesToCategoriesCommandTest < TestCase
    setup do
      @color_attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern",
        friendly_id: "color",
        handle: "color",
        values: [
          Value.new(
            id: 1,
            name: "Black",
            friendly_id: "color__black",
            handle: "color__black",
          ),
        ],
      )
      @size_attribute = Attribute.new(
        id: 2,
        name: "Size",
        description: "Defines the size of the product",
        friendly_id: "size",
        handle: "size",
        values: [
          Value.new(
            id: 2,
            name: "Small",
            friendly_id: "size__small",
            handle: "size__small",
          ),
        ],
      )

      Attribute.add(@color_attribute)
      Attribute.add(@size_attribute)
      Value.add(@color_attribute.values.first)
      Value.add(@size_attribute.values.first)

      @root = Category.new(id: "aa", name: "Apparel & Accessories")
      @clothing = Category.new(id: "aa-1", name: "Clothing")
      @shirts = Category.new(id: "aa-1-1", name: "Shirts")
      @root.add_child(@clothing)
      @clothing.add_child(@shirts)

      Category.add(@root)
      Category.add(@clothing)
      Category.add(@shirts)

      AddAttributesToCategoriesCommand.any_instance.stubs(:load_taxonomy)
      DumpCategoriesCommand.any_instance.stubs(:load_taxonomy)
      SyncEnLocalizationsCommand.any_instance.stubs(:load_taxonomy)
      GenerateDocsCommand.any_instance.stubs(:load_taxonomy)
    end

    test "execute adds attributes to specified categories" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributesToCategoriesCommand.new(
        attribute_friendly_ids: "color,size",
        category_ids: "aa-1",
        include_descendants: false
      ).execute

      assert_equal 2, @clothing.attributes.size
      assert_includes @clothing.attributes, @color_attribute
      assert_includes @clothing.attributes, @size_attribute

      assert_empty @root.attributes
      assert_empty @shirts.attributes
    end

    test "execute adds attributes to categories and their descendants when include_descendants is true" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributesToCategoriesCommand.new(
        attribute_friendly_ids: "color",
        category_ids: "aa-1",
        include_descendants: true
      ).execute

      assert_equal 1, @clothing.attributes.size
      assert_includes @clothing.attributes, @color_attribute

      assert_equal 1, @shirts.attributes.size
      assert_includes @shirts.attributes, @color_attribute

      assert_empty @root.attributes
    end

    test "execute adds attributes to multiple categories" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributesToCategoriesCommand.new(
        attribute_friendly_ids: "color",
        category_ids: "aa,aa-1",
        include_descendants: false
      ).execute

      assert_equal 1, @root.attributes.size
      assert_includes @root.attributes, @color_attribute

      assert_equal 1, @clothing.attributes.size
      assert_includes @clothing.attributes, @color_attribute

      assert_empty @shirts.attributes
    end

    test "execute skips adding attributes that are already present" do
      @clothing.add_attribute(@color_attribute)

      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributesToCategoriesCommand.new(
        attribute_friendly_ids: "color,size",
        category_ids: "aa-1",
        include_descendants: false
      ).execute

      assert_equal 2, @clothing.attributes.size
      assert_includes @clothing.attributes, @color_attribute
      assert_includes @clothing.attributes, @size_attribute

      assert_equal 1, @clothing.attributes.count { |attr| attr == @color_attribute }
    end

    test "execute raises error when attribute is not found" do
      assert_raises(RuntimeError) do
        AddAttributesToCategoriesCommand.new(
          attribute_friendly_ids: "nonexistent",
          category_ids: "aa-1",
          include_descendants: false
        ).execute
      end
    end

    test "execute raises error when category is not found" do
      assert_raises(RuntimeError) do
        AddAttributesToCategoriesCommand.new(
          attribute_friendly_ids: "color",
          category_ids: "nonexistent",
          include_descendants: false
        ).execute
      end
    end

    test "execute updates data files for all affected root categories" do
      # When adding attributes to categories from different verticals,
      # the command should update data files for all affected root categories
      @second_root = Category.new(id: "bb", name: "Business & Industrial")
      @equipment = Category.new(id: "bb-1", name: "Equipment")

      @second_root.add_child(@equipment)

      Category.add(@second_root)
      Category.add(@equipment)

      dump_command = mock
      dump_command.expects(:execute).once
      DumpCategoriesCommand.expects(:new).with(verticals: ["aa", "bb"]).returns(dump_command)

      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributesToCategoriesCommand.new(
        attribute_friendly_ids: "color",
        category_ids: "aa-1,bb-1",
        include_descendants: false
      ).execute

      assert_equal 1, @clothing.attributes.size
      assert_includes @clothing.attributes, @color_attribute

      assert_equal 1, @equipment.attributes.size
      assert_includes @equipment.attributes, @color_attribute
    end
  end
end
