# frozen_string_literal: true

module ProductTaxonomy
  class ReturnReason
    include ActiveModel::Validations
    include FormattedValidationErrors
    extend Localized
    extend Indexed

    class << self
      # Override to match folder name convention (return_reasons vs returnreasons)
      def localizations_humanized_model_name
        "return_reasons"
      end

      # Load return reasons from source data. By default, this data is deserialized from a YAML file in the `data` directory.
      #
      # @param source_data [Array<Hash>] The source data to load return reasons from.
      # @return [void]
      def load_from_source(source_data)
        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        source_data.each do |return_reason_data|
          raise ArgumentError, "source_data must contain hashes" unless return_reason_data.is_a?(Hash)

          return_reason = return_reason_from(return_reason_data)
          ReturnReason.add(return_reason)
          return_reason.validate!(:create)
        end
      end

      # Reset all class-level state
      def reset
        @localizations = nil
        @hashed_models = nil
      end

      # Get the next ID for a newly created return reason.
      #
      # @return [Integer] The next ID.
      def next_id = (all.max_by(&:id)&.id || 0) + 1

      private

      def return_reason_from(return_reason_data)
        ReturnReason.new(
          id: return_reason_data["id"],
          name: return_reason_data["name"],
          description: return_reason_data["description"],
          friendly_id: return_reason_data["friendly_id"],
          handle: return_reason_data["handle"],
        )
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }, on: :create
    validates :name, presence: true, on: :create
    validates :friendly_id, presence: true, on: :create
    validates :handle, presence: true, on: :create
    validates :description, presence: true, on: :create
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:friendly_id], on: :create

    localized_attr_reader :name, :description

    attr_reader :id, :friendly_id, :handle

    # @param id [Integer] The ID of the return reason.
    # @param name [String] The name of the return reason.
    # @param description [String] The description of the return reason.
    # @param friendly_id [String] The friendly ID of the return reason.
    # @param handle [String] The handle of the return reason.
    def initialize(id:, name:, description:, friendly_id:, handle:)
      @id = id
      @name = name
      @description = description
      @friendly_id = friendly_id
      @handle = handle
    end

    # The global ID of the return reason
    #
    # @return [String]
    def gid
      "gid://shopify/ReturnReasonDefinition/#{id}"
    end
  end
end

