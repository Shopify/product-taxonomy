# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddReturnReasonsToCategoriesCommandTest < TestCase
    setup do
      @defective_reason = ReturnReason.new(
        id: 1,
        name: "Defective or Doesn't Work",
        description: "Item is broken, defective, or doesn't function as expected",
        friendly_id: "defective_or_doesnt_work",
        handle: "defective-or-doesnt-work",
      )
      @wrong_size_reason = ReturnReason.new(
        id: 2,
        name: "Wrong Size or Fit",
        description: "Item doesn't fit properly or is not the expected size",
        friendly_id: "wrong_size_or_fit",
        handle: "wrong-size-or-fit",
      )
      @unknown_reason = ReturnReason.new(
        id: 3,
        name: "Unknown",
        description: "Unknown return reason",
        friendly_id: "unknown",
        handle: "unknown",
      )
      @other_reason = ReturnReason.new(
        id: 4,
        name: "Other",
        description: "Other return reason not listed",
        friendly_id: "other",
        handle: "other",
      )

      ReturnReason.add(@defective_reason)
      ReturnReason.add(@wrong_size_reason)
      ReturnReason.add(@unknown_reason)
      ReturnReason.add(@other_reason)

      @root = Category.new(id: "aa", name: "Apparel & Accessories")
      @clothing = Category.new(id: "aa-1", name: "Clothing")
      @shirts = Category.new(id: "aa-1-1", name: "Shirts")
      @root.add_child(@clothing)
      @clothing.add_child(@shirts)

      Category.add(@root)
      Category.add(@clothing)
      Category.add(@shirts)

      AddReturnReasonsToCategoriesCommand.any_instance.stubs(:load_taxonomy)
      DumpCategoriesCommand.any_instance.stubs(:load_taxonomy)
      SyncEnLocalizationsCommand.any_instance.stubs(:load_taxonomy)
      GenerateDocsCommand.any_instance.stubs(:load_taxonomy)
    end

    test "execute adds return reasons to specified categories" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work,wrong_size_or_fit",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      assert_equal 2, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason
      assert_includes @clothing.return_reasons, @wrong_size_reason

      assert_empty @root.return_reasons
      assert_empty @shirts.return_reasons
    end

    test "execute adds return reasons to categories and their descendants when include_descendants is true" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa-1",
        include_descendants: true,
      ).execute

      assert_equal 1, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason

      assert_equal 1, @shirts.return_reasons.size
      assert_includes @shirts.return_reasons, @defective_reason

      assert_empty @root.return_reasons
    end

    test "execute adds return reasons to multiple categories" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa,aa-1",
        include_descendants: false,
      ).execute

      assert_equal 1, @root.return_reasons.size
      assert_includes @root.return_reasons, @defective_reason

      assert_equal 1, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason

      assert_empty @shirts.return_reasons
    end

    test "execute skips adding return reasons that are already present" do
      @clothing.add_return_reason(@defective_reason)

      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work,wrong_size_or_fit",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      assert_equal 2, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason
      assert_includes @clothing.return_reasons, @wrong_size_reason

      assert_equal 1, @clothing.return_reasons.count { |reason| reason == @defective_reason }
    end

    test "execute sorts return reasons with special ones at the end" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "unknown,defective_or_doesnt_work,other,wrong_size_or_fit",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      assert_equal 4, @clothing.return_reasons.size

      # Check that regular reasons are sorted alphabetically
      regular_reasons = @clothing.return_reasons.take(2)
      assert_equal @defective_reason, regular_reasons[0]
      assert_equal @wrong_size_reason, regular_reasons[1]

      # Check that 'unknown' and 'other' are at the end in that order
      special_reasons = @clothing.return_reasons.drop(2)
      assert_equal @unknown_reason, special_reasons[0]
      assert_equal @other_reason, special_reasons[1]
    end

    test "execute raises error when return reason is not found" do
      assert_raises(Indexed::NotFoundError) do
        AddReturnReasonsToCategoriesCommand.new(
          return_reason_friendly_ids: "nonexistent",
          category_ids: "aa-1",
          include_descendants: false,
        ).execute
      end
    end

    test "execute raises error when category is not found" do
      assert_raises(Indexed::NotFoundError) do
        AddReturnReasonsToCategoriesCommand.new(
          return_reason_friendly_ids: "defective_or_doesnt_work",
          category_ids: "nonexistent",
          include_descendants: false,
        ).execute
      end
    end

    test "execute updates data files for all affected root categories" do
      # When adding return reasons to categories from different verticals,
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

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa-1,bb-1",
        include_descendants: false,
      ).execute

      assert_equal 1, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason

      assert_equal 1, @equipment.return_reasons.size
      assert_includes @equipment.return_reasons, @defective_reason
    end

    test "execute handles whitespace in comma-separated lists" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work , wrong_size_or_fit ",
        category_ids: " aa-1 , aa-1-1",
        include_descendants: false,
      ).execute

      assert_equal 2, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason
      assert_includes @clothing.return_reasons, @wrong_size_reason

      assert_equal 2, @shirts.return_reasons.size
      assert_includes @shirts.return_reasons, @defective_reason
      assert_includes @shirts.return_reasons, @wrong_size_reason
    end
  end
end
