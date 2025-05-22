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

    # Subclass of Model to test inheritance behavior with hashed_models
    class SubModel < Model
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

    test "add stores models in arrays" do
      second_model = Model.new(id: 2)
      Model.add(second_model)

      assert_instance_of Array, Model.hashed_models[:id][1]
      assert_instance_of Array, Model.hashed_models[:id][2]
      assert_equal [@model], Model.hashed_models[:id][1]
      assert_equal [second_model], Model.hashed_models[:id][2]
    end

    test "duplicate? returns true if the value exists and refers to a different model" do
      different_model = Model.new(id: 1)
      assert Model.duplicate?(model: different_model, field: :id)
    end

    test "duplicate? returns false if the value does not exist" do
      model = Model.new(id: 2)
      refute Model.duplicate?(model:, field: :id)
    end

    test "duplicate? returns false if the value exists but refers to the same model" do
      refute Model.duplicate?(model: @model, field: :id)
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

    test "find_by returns the first model with the specified field value" do
      assert_equal @model, Model.find_by(id: 1)
    end

    test "find_by returns nil if the model with the specified field value is not in the index" do
      assert_nil Model.find_by(id: 2)
    end

    test "find_by raises an error if the field is not hashed" do
      assert_raises(ArgumentError) { Model.find_by(name: "test") }
    end

    test "find_by! returns the first model with the specified field value" do
      assert_equal @model, Model.find_by!(id: 1)
    end

    test "find_by! raises NotFoundError if the model with the specified field value is not in the index" do
      assert_raises(ProductTaxonomy::Indexed::NotFoundError) do
        Model.find_by!(id: 2)
      end
    end

    test "all returns all models in the index" do
      assert_equal [@model], Model.all
    end

    test "all returns flattened array when multiple models exist" do
      second_model = Model.new(id: 2)
      Model.add(second_model)

      all_models = Model.all
      assert_equal 2, all_models.size
      assert_includes all_models, @model
      assert_includes all_models, second_model
    end

    test "self.extended sets @is_indexed to true on the extended class" do
      assert_equal true, Model.instance_variable_get(:@is_indexed)
    end

    test "create_validate_and_add! creates, validates, and adds a model to the index" do
      Model.reset
      model = Model.create_validate_and_add!(id: 2)

      assert_equal 2, model.id
      assert_equal 1, Model.size
      assert_equal model, Model.find_by(id: 2)
    end

    test "create_validate_and_add! validates with :create context" do
      Model.reset

      model_instance = Model.new(id: 2)
      Model.stubs(:new).returns(model_instance)
      model_instance.expects(:validate!).with(:create)

      Model.create_validate_and_add!(id: 2)
    end

    test "create_validate_and_add! raises an error if the model is not valid" do
      assert_raises(ActiveModel::ValidationError) do
        Model.create_validate_and_add!(id: 1)
      end
    end

    test "subclass shares hashed_models with parent class" do
      parent_model = Model.new(id: 2)
      Model.add(parent_model)

      sub_model = SubModel.new(id: 3)
      SubModel.add(sub_model)

      assert_equal 3, Model.size
      assert_equal 3, SubModel.size

      assert_equal parent_model, Model.find_by(id: 2)
      assert_equal sub_model, Model.find_by(id: 3)
      assert_equal parent_model, SubModel.find_by(id: 2)
      assert_equal sub_model, SubModel.find_by(id: 3)

      assert_same Model.hashed_models, SubModel.hashed_models
    end
  end
end
