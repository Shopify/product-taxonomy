# frozen_string_literal: true

require "test_helper"

module ProductTaxonomy
  class FormattedValidationErrorsTest < TestCase
    class CategoryModel
      include ActiveModel::Validations
      include FormattedValidationErrors

      attr_reader :id, :name

      validates :id, presence: true, format: { with: /\A[a-z]{2}(-\d+)*\z/ }
      validates :name, presence: true, length: { minimum: 2 }

      def initialize(id: nil, name: nil)
        @id = id
        @name = name
      end

      def is_a?(klass)
        klass == Category || super
      end
    end

    class AttributeModel
      include ActiveModel::Validations
      include FormattedValidationErrors

      attr_reader :friendly_id, :name, :handle

      validates :friendly_id, presence: true, format: { with: /\A[a-z_]+\z/ }
      validates :name, presence: true
      validates :handle, presence: true
      validate :validate_custom_base_error

      def initialize(friendly_id: nil, name: nil, handle: nil, has_base_error: false)
        @friendly_id = friendly_id
        @name = name
        @handle = handle
        @has_base_error = has_base_error
      end

      def validate_custom_base_error
        errors.add(:base, "Custom base error") if @has_base_error
      end
    end

    test "validate! passes through arguments to super" do
      model = CategoryModel.new(id: "aa", name: "Test")

      assert_nothing_raised { model.validate! }
      assert_nothing_raised { model.validate!(:create) }
      assert_nothing_raised { model.validate!(:update) }
    end

    test "validate! formats single attribute error for category-like model" do
      model = CategoryModel.new(id: "invalid-id", name: "Test")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for categorymodel with id=`invalid-id`:
          • id is invalid
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! formats single attribute error for non-category model" do
      model = AttributeModel.new(friendly_id: "invalid-friendly-id", name: "Test", handle: "test")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for attributemodel with friendly_id=`invalid-friendly-id`:
          • friendly_id is invalid
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! formats multiple attribute errors for category-like model" do
      model = CategoryModel.new(id: "", name: "")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for categorymodel with id=``:
          • id can't be blank
          • id is invalid
          • name can't be blank
          • name is too short (minimum is 2 characters)
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! formats multiple attribute errors for non-category model" do
      model = AttributeModel.new(friendly_id: "", name: "", handle: "")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for attributemodel with friendly_id=``:
          • friendly_id can't be blank
          • friendly_id is invalid
          • name can't be blank
          • handle can't be blank
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! handles base errors without attribute prefix" do
      model = AttributeModel.new(friendly_id: "aa", name: "Test", handle: "test", has_base_error: true)

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = "Validation failed for attributemodel with friendly_id=`aa`:\n  • Custom base error"
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! handles mixed attribute and base errors" do
      model = AttributeModel.new(friendly_id: "", name: "Test", handle: "test", has_base_error: true)

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for attributemodel with friendly_id=``:
          • friendly_id can't be blank
          • friendly_id is invalid
          • Custom base error
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! handles nil identifier values" do
      model = CategoryModel.new(id: nil, name: "Test")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      expected_message = <<~MESSAGE.chomp
        Validation failed for categorymodel with id=``:
          • id can't be blank
          • id is invalid
      MESSAGE
      assert_equal expected_message, error.message
      assert_equal model, error.model
    end

    test "validate! preserves original error model" do
      model = CategoryModel.new(id: "", name: "")

      error = assert_raises(ActiveModel::ValidationError) { model.validate! }

      assert_same model, error.model
      assert_instance_of CategoryModel, error.model
    end
  end
end
