# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class IndexedTest < TestCase
    class Model
      include ActiveModel::Validations
      extend Indexed

      class << self
        def reset
          @hashed_models = nil
        end
      end

      validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:id]

      attr_reader :id

      def initialize(id:)
        @id = id
      end
    end

    setup do
      @model = Model.new(id: 1)
      Model.add(@model)
    end

    teardown do
      Model.reset
    end

    test "add adds a model to the index" do
      assert_equal 1, Model.size
    end

    test "duplicate? returns true if the value exists and the model has not yet been added to the index" do
      model = Model.new(id: 1)
      assert Model.duplicate?(model:, field: :id)
    end

    test "duplicate? returns false if the value does not exist and the model has not yet been added to the index" do
      model = Model.new(id: 2)
      refute Model.duplicate?(model:, field: :id)
    end

    test "duplicate? returns true if the value exists and the model is already in the index" do
      model = Model.new(id: 1)
      Model.add(model)
      assert Model.duplicate?(model:, field: :id)
    end

    test "duplicate? returns false if the value does not exist and the model is already in the index" do
      model = Model.new(id: 2)
      Model.add(model)
      refute Model.duplicate?(model:, field: :id)
    end

    test "errors are added to a record with a uniqueness violation when the record is not in the index yet" do
      new_model = Model.new(id: 1)
      refute new_model.valid?
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, new_model.errors.details
    end

    test "errors are added to a record with a uniqueness violation when the record is already in the index" do
      new_model = Model.new(id: 1)
      Model.add(new_model)

      refute new_model.valid?
      expected_errors = {
        id: [{ error: :taken }],
      }
      assert_equal expected_errors, new_model.errors.details
    end

    test "find_by returns the model with the specified field value" do
      assert_equal @model, Model.find_by(id: 1)
    end

    test "find_by returns nil if the model with the specified field value is not in the index" do
      assert_nil Model.find_by(id: 2)
    end

    test "find_by raises an error if the field is not hashed" do
      assert_raises(ArgumentError) { Model.find_by(name: "test") }
    end

    test "all returns all models in the index" do
      assert_equal [@model], Model.all
    end
  end
end
