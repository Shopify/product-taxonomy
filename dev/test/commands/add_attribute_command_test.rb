# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class AddAttributeCommandTest < TestCase
    setup do
      @base_attribute = Attribute.new(
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

      Attribute.add(@base_attribute)
      Value.add(@base_attribute.values.first)

      AddAttributeCommand.any_instance.stubs(:load_taxonomy)
      DumpAttributesCommand.any_instance.stubs(:load_taxonomy)
      DumpValuesCommand.any_instance.stubs(:load_taxonomy)
      SyncEnLocalizationsCommand.any_instance.stubs(:load_taxonomy)
      GenerateDocsCommand.any_instance.stubs(:load_taxonomy)
    end

    test "execute successfully adds a new base attribute with values" do
      DumpAttributesCommand.any_instance.expects(:execute).once
      DumpValuesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributeCommand.new(
        name: "Size",
        description: "Product size information",
        values: "Small, Medium, Large",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "size")
      assert_not_nil new_attribute
      assert_equal 2, new_attribute.id # Since id 1 already exists
      assert_equal "Size", new_attribute.name
      assert_equal "Product size information", new_attribute.description
      assert_equal "size", new_attribute.friendly_id
      assert_equal "size", new_attribute.handle

      assert_equal 3, new_attribute.values.size
      value_names = new_attribute.values.map(&:name)
      assert_includes value_names, "Small"
      assert_includes value_names, "Medium"
      assert_includes value_names, "Large"

      value_friendly_ids = new_attribute.values.map(&:friendly_id)
      assert_includes value_friendly_ids, "size__small"
      assert_includes value_friendly_ids, "size__medium"
      assert_includes value_friendly_ids, "size__large"
    end

    test "execute successfully adds a new measurement attribute" do
      stub_commands

      AddAttributeCommand.new(
        name: "Height",
        description: "Specifies the vertical measurement from bottom to top",
        type: "measurement",
        measurement_type: "dimension",
        supported_units: "cm, in",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "height")
      assert_not_nil new_attribute
      assert_equal 2, new_attribute.id
      assert_equal "Height", new_attribute.name
      assert_equal "Specifies the vertical measurement from bottom to top", new_attribute.description
      assert_equal "height", new_attribute.friendly_id
      assert_equal "height", new_attribute.handle
      assert_equal "measurement", new_attribute.type
      assert_equal "dimension", new_attribute.measurement_type
      assert_equal ["cm", "in"], new_attribute.supported_units
      assert_empty new_attribute.values
    end

    test "execute successfully adds an extended attribute" do
      DumpAttributesCommand.any_instance.expects(:execute).once
      DumpValuesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.any_instance.expects(:execute).once
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributeCommand.new(
        name: "Clothing Color",
        description: "Color of clothing items",
        base_attribute_friendly_id: "color",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "clothing_color")
      assert_not_nil new_attribute
      assert_instance_of ExtendedAttribute, new_attribute
      assert_equal "Clothing Color", new_attribute.name
      assert_equal "Color of clothing items", new_attribute.description
      assert_equal "clothing_color", new_attribute.friendly_id
      assert_equal "clothing-color", new_attribute.handle

      assert_equal @base_attribute, new_attribute.base_attribute

      assert_equal @base_attribute.values.size, new_attribute.values.size
      assert_equal @base_attribute.values.first.name, new_attribute.values.first.name
    end

    test "execute successfully adds a measurement-backed extended attribute" do
      measurement_attribute = Attribute.new(
        id: 2,
        name: "Height",
        description: "Specifies the vertical measurement from bottom to top",
        friendly_id: "height",
        handle: "height",
        type: "measurement",
        measurement_type: "dimension",
        supported_units: ["cm", "in"],
      )
      Attribute.add(measurement_attribute)

      stub_commands

      AddAttributeCommand.new(
        name: "Interior Height",
        description: "Specifies the interior vertical measurement from bottom to top",
        base_attribute_friendly_id: "height",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "interior_height")
      assert_not_nil new_attribute
      assert_instance_of ExtendedAttribute, new_attribute
      assert_equal measurement_attribute, new_attribute.base_attribute
      assert_equal "measurement", new_attribute.type
      assert_equal "dimension", new_attribute.measurement_type
      assert_equal ["cm", "in"], new_attribute.supported_units
      assert_empty new_attribute.values
    end

    test "execute raises error when creating base attribute without values" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Material",
          description: "Product material information",
          values: "",
        ).execute
      end
    end

    test "execute raises error when creating measurement attribute without measurement_type" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Height",
          description: "Specifies the vertical measurement from bottom to top",
          type: "measurement",
          supported_units: "cm, in",
        ).execute
      end
    end

    test "execute raises error when creating measurement attribute without supported_units" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Height",
          description: "Specifies the vertical measurement from bottom to top",
          type: "measurement",
          measurement_type: "dimension",
        ).execute
      end
    end

    test "execute raises error when creating measurement attribute with values" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Height",
          description: "Specifies the vertical measurement from bottom to top",
          type: "measurement",
          measurement_type: "dimension",
          supported_units: "cm, in",
          values: "Short, Tall",
        ).execute
      end
    end

    test "execute raises error when creating closed-list attribute with measurement metadata" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Size",
          description: "Product size information",
          values: "Small, Medium, Large",
          measurement_type: "dimension",
          supported_units: "cm, in",
        ).execute
      end
    end

    test "execute raises error when creating extended attribute with values" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Clothing Color",
          description: "Color of clothing items",
          base_attribute_friendly_id: "color",
          values: "Red, Blue",
        ).execute
      end
    end

    test "execute raises error when creating extended attribute with measurement options" do
      stub_commands

      assert_raises(RuntimeError) do
        AddAttributeCommand.new(
          name: "Clothing Color",
          description: "Color of clothing items",
          base_attribute_friendly_id: "color",
          type: "measurement",
          measurement_type: "dimension",
          supported_units: "cm, in",
        ).execute
      end
    end

    test "execute raises error when base attribute for extended attribute doesn't exist" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddAttributeCommand.new(
          name: "Clothing Material",
          description: "Material of clothing items",
          base_attribute_friendly_id: "nonexistent",
        ).execute
      end
    end

    test "execute raises error when attribute with same friendly_id already exists" do
      stub_commands

      assert_raises(ActiveModel::ValidationError) do
        AddAttributeCommand.new(
          name: "Color", # This will generate the same friendly_id as @base_attribute
          description: "Another color attribute",
          values: "Red, Blue",
        ).execute
      end
    end

    test "execute creates values with correct friendly_ids and handles" do
      stub_commands

      AddAttributeCommand.new(
        name: "Material Type",
        description: "Type of material used",
        values: "Cotton, Polyester",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "material_type")
      assert_not_nil new_attribute

      cotton_value = new_attribute.values.find { |v| v.name == "Cotton" }
      assert_not_nil cotton_value
      assert_equal "material_type__cotton", cotton_value.friendly_id
      assert_equal "material-type__cotton", cotton_value.handle

      polyester_value = new_attribute.values.find { |v| v.name == "Polyester" }
      assert_not_nil polyester_value
      assert_equal "material_type__polyester", polyester_value.friendly_id
      assert_equal "material-type__polyester", polyester_value.handle
    end

    test "execute reuses existing values with same friendly_id" do
      existing_value = Value.new(
        id: 2,
        name: "Existing Cotton",
        friendly_id: "material_type__cotton",
        handle: "material_type__cotton",
      )
      Value.add(existing_value)

      stub_commands

      AddAttributeCommand.new(
        name: "Material Type",
        description: "Type of material used",
        values: "Cotton, Polyester",
      ).execute

      new_attribute = Attribute.find_by(friendly_id: "material_type")
      assert_not_nil new_attribute

      cotton_value = new_attribute.values.find { |v| v.friendly_id == "material_type__cotton" }
      assert_not_nil cotton_value
      assert_equal existing_value, cotton_value
      assert_equal "Existing Cotton", cotton_value.name # Name from existing value

      polyester_value = new_attribute.values.find { |v| v.name == "Polyester" }
      assert_not_nil polyester_value
      assert_equal "material_type__polyester", polyester_value.friendly_id
    end

    test "execute updates data files after creating attribute" do
      DumpAttributesCommand.any_instance.expects(:execute).once
      DumpValuesCommand.any_instance.expects(:execute).once
      SyncEnLocalizationsCommand.expects(:new).with(targets: "attributes,values").returns(stub(execute: true))
      GenerateDocsCommand.any_instance.expects(:execute).once

      AddAttributeCommand.new(
        name: "Size",
        description: "Product size information",
        values: "Small, Medium, Large",
      ).execute
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
