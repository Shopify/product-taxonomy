# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddCategoryCommandTest < TestCase
    setup do
      @root_category = Category.new(id: "aa", name: "Root Category")
      @child_category = Category.new(id: "aa-1", name: "Child Category", parent: @root_category)
      @root_category.add_child(@child_category)

      Category.add(@root_category)
      Category.add(@child_category)
    end

    test "execute successfully adds a new category" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddCategoryCommand.new(name: "New Category", parent_id: "aa").execute

      new_category = @root_category.children.find { |c| c.name == "New Category" }
      assert_not_nil new_category
      assert_equal "aa-2", new_category.id  # Since aa-1 already exists
      assert_equal "New Category", new_category.name
      assert_equal @root_category, new_category.parent
      assert_not_nil Category.find_by(id: "aa-2")
    end

    test "execute successfully adds a category with custom numeric ID" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddCategoryCommand.new(name: "Custom ID Category", parent_id: "aa", id: "aa-5").execute

      new_category = @root_category.children.find { |c| c.name == "Custom ID Category" }
      assert_not_nil new_category
      assert_equal "aa-5", new_category.id
      assert_equal "Custom ID Category", new_category.name
      assert_equal @root_category, new_category.parent
      assert_not_nil Category.find_by(id: "aa-5")
    end

    test "execute raises error when parent category not found" do
      stub_commands

      assert_raises(Indexed::NotFoundError) do
        AddCategoryCommand.new(name: "New Category", parent_id: "nonexistent").execute
      end
    end

    test "execute raises error when category ID already exists" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddCategoryCommand.new(name: "Duplicate ID", parent_id: "aa", id: "aa-1").execute
      end
    end

    test "execute raises error when category ID format is invalid" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddCategoryCommand.new(name: "Invalid ID", parent_id: "aa", id: "aa-custom").execute
      end
    end

    test "execute raises error when category name is invalid" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddCategoryCommand.new(name: "", parent_id: "aa").execute
      end
    end

    test "execute updates correct vertical based on parent category" do
      DumpCategoriesCommand.expects(:new).with(verticals: ["aa"]).returns(stub(execute: true))
      SyncEnLocalizationsCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)

      AddCategoryCommand.new(name: "New Category", parent_id: "aa").execute

      new_category = @root_category.children.find { |c| c.name == "New Category" }
      assert_not_nil new_category
      assert_equal @root_category, new_category.parent
      assert_not_nil Category.find_by(id: "aa-2")
    end

    test "execute generates sequential IDs correctly" do
      stub_commands

      AddCategoryCommand.new(name: "First New", parent_id: "aa").execute
      AddCategoryCommand.new(name: "Second New", parent_id: "aa").execute

      new_categories = @root_category.children.select { |c| c.name.include?("New") }.sort_by(&:id)
      assert_equal 2, new_categories.size
      assert_equal "aa-2", new_categories[0].id
      assert_equal "aa-3", new_categories[1].id
      assert_equal "First New", new_categories[0].name
      assert_equal "Second New", new_categories[1].name
      assert_not_nil Category.find_by(id: "aa-2")
      assert_not_nil Category.find_by(id: "aa-3")
    end

    private

    def stub_commands
      DumpCategoriesCommand.any_instance.stubs(:execute)
      SyncEnLocalizationsCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)
    end
  end
end
