# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ModelIndexTest < ActiveSupport::TestCase
    setup do
      @model_index = ModelIndex.new(Value)
      @models = [Value.new(
        id: 1,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )]
      @model_index.add(@models.first)
    end

    test "add adds a model to the index" do
      assert_equal 1, @model_index.size
    end

    test "duplicate? returns true if the value exists and the model has not yet been added to the index" do
      model = Value.new(
        id: 2,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )
      assert @model_index.duplicate?(model:, field: :friendly_id)
    end

    test "duplicate? returns false if the value does not exist and the model has not yet been added to the index" do
      model = Value.new(
        id: 2,
        name: "Blue",
        friendly_id: "color__blue",
        handle: "color__blue",
        uniqueness_context: @model_index,
      )
      refute @model_index.duplicate?(model:, field: :friendly_id)
    end

    test "duplicate? returns true if the value exists and the model is already in the index" do
      model = Value.new(
        id: 2,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )
      @model_index.add(model)
      assert @model_index.duplicate?(model:, field: :friendly_id)
    end

    test "duplicate? returns false if the value does not exist and the model is already in the index" do
      model = Value.new(
        id: 2,
        name: "Blue",
        friendly_id: "color__blue",
        handle: "color__blue",
        uniqueness_context: @model_index,
      )
      @model_index.add(model)
      refute @model_index.duplicate?(model:, field: :friendly_id)
    end

    test "errors are added to a record with a uniqueness violation when the record is not in the index yet" do
      new_value = Value.new(
        id: 2,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )

      refute new_value.valid?
      expected_errors = {
        friendly_id: [{ error: :taken }],
        handle: [{ error: :taken }],
      }
      assert_equal expected_errors, new_value.errors.details
    end

    test "errors are added to a record with a uniqueness violation when the record is already in the index" do
      new_value = Value.new(
        id: 2,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )
      @model_index.add(new_value)

      refute new_value.valid?
      expected_errors = {
        friendly_id: [{ error: :taken }],
        handle: [{ error: :taken }],
      }
      assert_equal expected_errors, new_value.errors.details
    end

    test "hashed_by returns a hash of models indexed by the specified field" do
      assert_equal({ "color__black" => @models.first }, @model_index.hashed_by(:friendly_id))
    end
  end
end
