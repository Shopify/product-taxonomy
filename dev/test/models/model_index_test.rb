# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class ModelIndexTest < ActiveSupport::TestCase
    setup do
      @model_index = ModelIndex.new(Value, hashed_by: [:friendly_id])
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

    test "exists? returns true if the value exists" do
      assert @model_index.exists?(handle: "color__black")
    end

    test "exists? returns false if the value does not exist" do
      refute @model_index.exists?(handle: "color__blue")
    end

    test "errors are added to a record with a uniqueness violation" do
      new_value = Value.new(
        id: 2,
        name: "Black",
        friendly_id: "color__black",
        handle: "color__black",
        uniqueness_context: @model_index,
      )

      refute new_value.valid?
      assert_equal ["\"color__black\" has already been used"], new_value.errors[:friendly_id]
    end

    test "hashed_by returns a hash of models indexed by the specified field" do
      assert_equal({ "color__black" => @models.first }, @model_index.hashed_by(:friendly_id))
    end
  end
end
