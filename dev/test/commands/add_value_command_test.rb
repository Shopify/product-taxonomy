# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddValueCommandTest < TestCase
    setup do
      @attribute = Attribute.new(
        id: 1,
        name: "Color",
        description: "Defines the primary color or pattern",
        friendly_id: "color",
        handle: "color",
        values: []
      )
      @extended_attribute = ExtendedAttribute.new(
        name: "Clothing Color",
        description: "Color of the clothing",
        friendly_id: "clothing_color",
        handle: "clothing_color",
        values_from: @attribute
      )
      @existing_value = Value.new(
        id: 1,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black"
      )
      @attribute.add_value(@existing_value)

      Attribute.add(@attribute)
      Attribute.add(@extended_attribute)
      Value.add(@existing_value)

      AddValueCommand.any_instance.stubs(:load_taxonomy)
      DumpAttributesCommand.any_instance.stubs(:load_taxonomy)
      DumpValuesCommand.any_instance.stubs(:load_taxonomy)
      SyncEnLocalizationsCommand.any_instance.stubs(:load_taxonomy)
      GenerateDocsCommand.any_instance.stubs(:load_taxonomy)
    end

    test "execute successfully adds a new value to an attribute" do
      DumpAttributesCommand.any_instance.expects(:execute).once
      DumpValuesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddValueCommand.new(name: "Blue", attribute_friendly_id: "color").execute

      new_value = @attribute.values.find { |v| v.name == "Blue" }
      assert_not_nil new_value
      assert_equal 2, new_value.id  # Since id 1 already exists
      assert_equal "Blue", new_value.name
      assert_equal "color__blue", new_value.friendly_id
      assert_equal "color__blue", new_value.handle
      assert_not_nil Value.find_by(friendly_id: "color__blue")
    end

    test "execute raises error when attribute not found" do
      stub_commands

      assert_raises(Indexed::NotFoundError) do
        AddValueCommand.new(name: "Blue", attribute_friendly_id: "nonexistent").execute
      end
    end

    test "execute raises error when trying to add value to extended attribute" do
      stub_commands

      assert_raises(RuntimeError) do
        AddValueCommand.new(name: "Blue", attribute_friendly_id: "clothing_color").execute
      end
    end

    test "execute raises error when value already exists" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddValueCommand.new(name: "Black", attribute_friendly_id: "color").execute
      end
    end

    test "execute warns when attribute has custom sorting" do
      @attribute.stubs(:manually_sorted?).returns(true)

      stub_commands

      logger = mock
      logger.expects(:info).once
      logger.expects(:warn).once.with(regexp_matches(/custom sorting/))

      command = AddValueCommand.new(name: "Blue", attribute_friendly_id: "color")
      command.stubs(:logger).returns(logger)
      command.execute

      new_value = @attribute.values.find { |v| v.name == "Blue" }
      assert_not_nil new_value
    end

    test "execute generates correct friendly_id and handle" do
      stub_commands

      IdentifierFormatter.expects(:format_friendly_id).with("color__Multi Word").returns("color__multi_word")
      IdentifierFormatter.expects(:format_handle).with("color__multi_word").returns("color__multi_word")

      AddValueCommand.new(name: "Multi Word", attribute_friendly_id: "color").execute

      new_value = @attribute.values.find { |v| v.name == "Multi Word" }
      assert_not_nil new_value
      assert_equal "color__multi_word", new_value.friendly_id
      assert_equal "color__multi_word", new_value.handle
    end

    test "execute calls update_data_files! with correct options" do
      options = { name: "Blue", attribute_friendly_id: "color" }

      DumpAttributesCommand.expects(:new).with(options).returns(stub(execute: true))
      DumpValuesCommand.expects(:new).with(options).returns(stub(execute: true))
      SyncEnLocalizationsCommand.expects(:new).with(targets: "values").returns(stub(execute: true))
      GenerateDocsCommand.expects(:new).with({}).returns(stub(execute: true))

      AddValueCommand.new(options).execute
    end

    test "execute assigns sequential IDs correctly" do
      stub_commands

      AddValueCommand.new(name: "Blue", attribute_friendly_id: "color").execute
      AddValueCommand.new(name: "Green", attribute_friendly_id: "color").execute

      new_values = @attribute.values.select { |v| v.name != "Black" }.sort_by(&:id)
      assert_equal 2, new_values.size
      assert_equal 2, new_values[0].id
      assert_equal 3, new_values[1].id
      assert_equal "Blue", new_values[0].name
      assert_equal "Green", new_values[1].name
      assert_not_nil Value.find_by(friendly_id: "color__blue")
      assert_not_nil Value.find_by(friendly_id: "color__green")
    end

    private

    def stub_commands
      DumpAttributesCommand.any_instance.stubs(:execute)
      DumpValuesCommand.any_instance.stubs(:execute)
      SyncEnLocalizationsCommand.any_instance.stubs(:execute)
      GenerateDocsCommand.any_instance.stubs(:execute)
    end
  end
end
