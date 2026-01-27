# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddReturnReasonCommandTest < TestCase
    setup do
      @existing_return_reason = ReturnReason.new(
        id: 1,
        name: "Defective or Doesn't Work",
        description: "Item is broken, defective, or doesn't function as expected",
        friendly_id: "defective_or_doesnt_work",
        handle: "defective-or-doesnt-work",
      )

      ReturnReason.add(@existing_return_reason)

      AddReturnReasonCommand.any_instance.stubs(:load_taxonomy)
      DumpReturnReasonsCommand.any_instance.stubs(:load_taxonomy)
      SyncEnLocalizationsCommand.any_instance.stubs(:load_taxonomy)
      GenerateDocsCommand.any_instance.stubs(:load_taxonomy)
    end

    test "execute successfully adds a new return reason" do
      DumpReturnReasonsCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.expects(:new).with(targets: "return_reasons").returns(stub(execute: true))
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonCommand.new(
        name: "Wrong Size or Fit",
        description: "Item doesn't fit properly or is not the expected size",
      ).execute

      new_return_reason = ReturnReason.find_by(friendly_id: "wrong_size_or_fit")
      assert_not_nil new_return_reason
      assert_equal 2, new_return_reason.id # Since id 1 already exists
      assert_equal "Wrong Size or Fit", new_return_reason.name
      assert_equal "Item doesn't fit properly or is not the expected size", new_return_reason.description
      assert_equal "wrong_size_or_fit", new_return_reason.friendly_id
      assert_equal "wrong-size-or-fit", new_return_reason.handle
    end

    test "execute generates correct friendly_id and handle from name" do
      stub_commands

      AddReturnReasonCommand.new(
        name: "Not As Described",
        description: "Item received differs from the product description",
      ).execute

      new_return_reason = ReturnReason.find_by(friendly_id: "not_as_described")
      assert_not_nil new_return_reason
      assert_equal "not_as_described", new_return_reason.friendly_id
      assert_equal "not-as-described", new_return_reason.handle
    end

    test "execute raises error when return reason with same friendly_id already exists" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddReturnReasonCommand.new(
          name: "Defective or Doesn't Work", # This will generate the same friendly_id as @existing_return_reason
          description: "Another defective description",
        ).execute
      end
    end

    test "execute raises error when name is empty" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddReturnReasonCommand.new(
          name: "",
          description: "Valid description",
        ).execute
      end
    end

    test "execute raises error when description is empty" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddReturnReasonCommand.new(
          name: "Valid Name",
          description: "",
        ).execute
      end
    end

    test "execute updates data files after creating return reason" do
      DumpReturnReasonsCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.expects(:new).with(targets: "return_reasons").returns(stub(execute: true))
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddReturnReasonCommand.new(
        name: "Changed My Mind",
        description: "Customer no longer wants the item",
      ).execute
    end

    test "execute assigns sequential IDs to multiple return reasons" do
      stub_commands

      AddReturnReasonCommand.new(
        name: "First Reason",
        description: "First description",
      ).execute

      first_reason = ReturnReason.find_by(friendly_id: "first_reason")
      assert_equal 2, first_reason.id

      AddReturnReasonCommand.new(
        name: "Second Reason",
        description: "Second description",
      ).execute

      second_reason = ReturnReason.find_by(friendly_id: "second_reason")
      assert_equal 3, second_reason.id
    end

    test "execute handles special characters in name properly" do
      stub_commands

      AddReturnReasonCommand.new(
        name: "Item's Quality & Appearance (Not Good!)",
        description: "Quality or appearance issues with the product",
      ).execute

      new_return_reason = ReturnReason.find_by(friendly_id: "items_quality_appearance_not_good")
      assert_not_nil new_return_reason
      assert_equal "Item's Quality & Appearance (Not Good!)", new_return_reason.name
      assert_equal "items_quality_appearance_not_good", new_return_reason.friendly_id
      assert_equal "items-quality-appearance-not-good", new_return_reason.handle
    end

    private

    def stub_commands
      DumpReturnReasonsCommand.any_instance.stubs(:execute)
      SyncEnLocalizationsCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)
    end
  end
end
