# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddReturnReasonsToCategoriesCommandTest < TestCase
    setup do
      @defective_reason = ReturnReason.new(
        id: 1001,
        name: "Defective or Doesn't Work",
        description: "Item is broken, defective, or doesn't function as expected",
        friendly_id: "defective_or_doesnt_work",
        handle: "defective-or-doesnt-work",
      )
      @wrong_size_reason = ReturnReason.new(
        id: 1002,
        name: "Wrong Size or Fit",
        description: "Item doesn't fit properly or is not the expected size",
        friendly_id: "wrong_size_or_fit",
        handle: "wrong-size-or-fit",
      )
      @unknown_reason = ReturnReason.new(
        id: 1,
        name: "Unknown",
        description: "The reason for the return has not been specified or could not be determined.",
        friendly_id: "unknown",
        handle: "unknown",
      )
      @other_reason = ReturnReason.new(
        id: 5,
        name: "Other",
        description: "The reason for the return does not fit into any of the predefined categories.",
        friendly_id: "other_reason",
        handle: "other-reason",
      )

      @changed_my_mind_reason = ReturnReason.new(
        id: 2,
        name: "Changed my mind",
        description: "The customer no longer wants the item after purchasing it, regardless of product " \
          "quality or accuracy.",
        friendly_id: "changed_my_mind",
        handle: "changed-my-mind",
      )
      @item_not_as_described_reason = ReturnReason.new(
        id: 3,
        name: "Item not as described",
        description: "The product does not match the description, images, or specifications provided in " \
          "the listing.",
        friendly_id: "item_not_as_described",
        handle: "item-not-as-described",
      )
      @received_wrong_item_reason = ReturnReason.new(
        id: 4,
        name: "Received the wrong item",
        description: "The customer received a different product than what was ordered or expected.",
        friendly_id: "received_the_wrong_item",
        handle: "received-the-wrong-item",
      )
      @damaged_or_defective_reason = ReturnReason.new(
        id: 6,
        name: "Damaged or defective",
        description: "The item arrived with physical damage, manufacturing defects, or does not function " \
          "as intended.",
        friendly_id: "damaged_or_defective",
        handle: "damaged-or-defective",
      )

      @existing_reason = ReturnReason.new(
        id: 1003,
        name: "Existing Reason",
        description: "A reason already present on the category before the command runs",
        friendly_id: "existing_reason",
        handle: "existing-reason",
      )

      ReturnReason.add(@defective_reason)
      ReturnReason.add(@wrong_size_reason)
      ReturnReason.add(@unknown_reason)
      ReturnReason.add(@other_reason)
      ReturnReason.add(@changed_my_mind_reason)
      ReturnReason.add(@item_not_as_described_reason)
      ReturnReason.add(@received_wrong_item_reason)
      ReturnReason.add(@damaged_or_defective_reason)
      ReturnReason.add(@existing_reason)

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
      @clothing.add_return_reason(@existing_reason)

      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work,wrong_size_or_fit",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      assert_equal 3, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @existing_reason
      assert_includes @clothing.return_reasons, @defective_reason
      assert_includes @clothing.return_reasons, @wrong_size_reason

      assert_empty @root.return_reasons
      assert_empty @shirts.return_reasons
    end

    test "execute appends the global reasons when a category starts from an empty list" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "wrong_size_or_fit",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      # The added reason keeps its spot at the front; the six global reasons follow in their defined order.
      assert_equal(
        [
          "wrong_size_or_fit",
          "changed_my_mind",
          "item_not_as_described",
          "received_the_wrong_item",
          "damaged_or_defective",
          "unknown",
          "other_reason",
        ],
        @clothing.return_reasons.map(&:friendly_id),
      )
    end

    test "execute adds return reasons to categories and their descendants when include_descendants is true" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      @clothing.add_return_reason(@existing_reason)
      @shirts.add_return_reason(@existing_reason)

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa-1",
        include_descendants: true,
      ).execute

      assert_equal 2, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason

      assert_equal 2, @shirts.return_reasons.size
      assert_includes @shirts.return_reasons, @defective_reason

      assert_empty @root.return_reasons
    end

    test "execute adds return reasons to multiple categories" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      @root.add_return_reason(@existing_reason)
      @clothing.add_return_reason(@existing_reason)

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa,aa-1",
        include_descendants: false,
      ).execute

      assert_equal 2, @root.return_reasons.size
      assert_includes @root.return_reasons, @defective_reason

      assert_equal 2, @clothing.return_reasons.size
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

    test "execute keeps non-global reasons in order and moves the global reasons to the end in their defined order" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids:
          "other_reason,changed_my_mind,wrong_size_or_fit,unknown,damaged_or_defective," \
          "defective_or_doesnt_work,received_the_wrong_item,item_not_as_described",
        category_ids: "aa-1",
        include_descendants: false,
      ).execute

      # Non-global reasons keep the given order at the front; the global reasons follow in their defined order.
      assert_equal(
        [
          "wrong_size_or_fit",
          "defective_or_doesnt_work",
          "changed_my_mind",
          "item_not_as_described",
          "received_the_wrong_item",
          "damaged_or_defective",
          "unknown",
          "other_reason",
        ],
        @clothing.return_reasons.map(&:friendly_id),
      )
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

      @clothing.add_return_reason(@existing_reason)
      @equipment.add_return_reason(@existing_reason)

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

      assert_equal 2, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason

      assert_equal 2, @equipment.return_reasons.size
      assert_includes @equipment.return_reasons, @defective_reason
    end

    test "execute on a category that inherits its return reasons turns off inheritance and appends the global reasons" do
      # `aa-2` inherits from its parent `aa`, which defines its own reasons.
      @root.add_return_reason(@wrong_size_reason)
      shoes = Category.new(id: "aa-2", name: "Shoes", return_reasons: :inherit)
      @root.add_child(shoes)
      Category.add(shoes)
      shoes.resolve_inherited_return_reasons

      assert shoes.inherits_return_reasons
      assert_equal [@wrong_size_reason], shoes.return_reasons

      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa-2",
        include_descendants: false,
      ).execute

      # Adding a reason turns off inheritance and discards the inherited reasons; since the category now starts
      # from scratch, the global reasons are appended after the new reason.
      refute shoes.inherits_return_reasons
      expected = [
        "defective_or_doesnt_work",
        "changed_my_mind",
        "item_not_as_described",
        "received_the_wrong_item",
        "damaged_or_defective",
        "unknown",
        "other_reason",
      ]
      assert_equal expected, shoes.return_reasons.map(&:friendly_id)
      assert_equal expected, Serializers::Category::Data::DataSerializer.serialize(shoes)["return_reasons"]
    end

    test "execute does not skip a reason the category only has through inheritance, materializing it instead" do
      # `aa-2` inherits from its parent `aa`, whose reasons already include the one we add.
      @root.add_return_reason(@defective_reason)
      shoes = Category.new(id: "aa-2", name: "Shoes", return_reasons: :inherit)
      @root.add_child(shoes)
      Category.add(shoes)
      shoes.resolve_inherited_return_reasons

      assert shoes.inherits_return_reasons
      assert_equal [@defective_reason], shoes.return_reasons

      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work",
        category_ids: "aa-2",
        include_descendants: false,
      ).execute

      # Even though the reason is present via inheritance, the command still adds it, turning off inheritance.
      refute shoes.inherits_return_reasons
      assert_includes shoes.return_reasons, @defective_reason
    end

    test "execute handles whitespace in comma-separated lists" do
      DumpCategoriesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      @clothing.add_return_reason(@existing_reason)
      @shirts.add_return_reason(@existing_reason)

      AddReturnReasonsToCategoriesCommand.new(
        return_reason_friendly_ids: "defective_or_doesnt_work , wrong_size_or_fit ",
        category_ids: " aa-1 , aa-1-1",
        include_descendants: false,
      ).execute

      assert_equal 3, @clothing.return_reasons.size
      assert_includes @clothing.return_reasons, @defective_reason
      assert_includes @clothing.return_reasons, @wrong_size_reason

      assert_equal 3, @shirts.return_reasons.size
      assert_includes @shirts.return_reasons, @defective_reason
      assert_includes @shirts.return_reasons, @wrong_size_reason
    end
  end
end
