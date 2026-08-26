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

    test "execute marks new categories as inheriting return reasons by default" do
      stub_commands

      AddCategoryCommand.new(name: "New Category", parent_id: "aa").execute

      assert_equal true, Category.find_by(id: "aa-2").inherits_return_reasons
    end

    test "execute lets the caller opt out of inheriting return reasons" do
      stub_commands

      AddCategoryCommand.new(name: "New Category", parent_id: "aa", inherits_return_reasons: false).execute

      new_category = Category.find_by(id: "aa-2")
      assert_equal false, new_category.inherits_return_reasons
      assert_equal [], new_category.return_reasons
      assert_empty new_category.defined_return_reasons
    end

    test "execute gives a category that opts out of inheriting the global reasons, keeping `[]` in the data file" do
      stub_commands
      ReturnReason::GLOBAL_FRIENDLY_IDS.each_with_index do |friendly_id, index|
        ReturnReason.add(ReturnReason.new(
          id: index + 1,
          name: friendly_id.tr("_", " ").capitalize,
          description: friendly_id,
          friendly_id:,
          handle: friendly_id.tr("_", "-"),
        ))
      end

      AddCategoryCommand.new(name: "New Category", parent_id: "aa", inherits_return_reasons: false).execute

      new_category = Category.find_by(id: "aa-2")
      # The category resolves to the global baseline like one loaded from source...
      assert_equal ReturnReason::GLOBAL_FRIENDLY_IDS, new_category.return_reasons.map(&:friendly_id)
      # ...but it defines none of them, so the dumped data file keeps `[]` and a future global reason is picked up
      # automatically.
      assert_empty new_category.defined_return_reasons
      assert_equal(
        [],
        Serializers::Category::Data::DataSerializer.serialize(new_category)["return_reasons"],
      )
    end

    test "execute copies inherited reasons from the closest defining ancestor onto the new category" do
      stub_commands
      return_reason = ReturnReason.new(
        id: 1,
        name: "Too big",
        description: "Too big",
        friendly_id: "too_big",
        handle: "too-big",
      )
      @root_category.add_return_reason(return_reason)

      AddCategoryCommand.new(name: "New Category", parent_id: "aa").execute

      new_category = Category.find_by(id: "aa-2")
      assert_equal true, new_category.inherits_return_reasons
      assert_equal ["too_big"], new_category.return_reasons.map(&:friendly_id)
      # The reasons come from the ancestor, so the new category defines none and stays `inherit` in the data file.
      assert_empty new_category.defined_return_reasons
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
