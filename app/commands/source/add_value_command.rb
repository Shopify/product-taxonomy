# frozen_string_literal: true

module Source
  class AddValueCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :name do
      desc "Name for the new value"
      required
    end

    keyword :attribute_friendly_id do
      desc "Friendly ID of the primary attribute to add the value to"
      required
    end

    def execute
      frame("Adding new value") do
        ActiveRecord::Base.transaction do
          setup!
          create_value!
          create_attributes_value!
        rescue ActiveRecord::Rollback => e
          logger.fatal(e.message)
          exit(1)
        end

        update_data_files!
      end
    end

    private

    def setup!
      @primary_attribute = Attribute.find_by(friendly_id: params[:attribute_friendly_id])

      raise ActiveRecord::Rollback,
        "Primary attribute `#{params[:attribute_friendly_id]}` not found" if @primary_attribute.nil?

      @extended_attributes = @primary_attribute.extended_attributes
    end

    def create_value!
      @new_value = Value.find_or_create_for_attribute(@primary_attribute, params[:name])

      return if @new_value.persisted?

      raise ActiveRecord::Rollback, "Failed to create value: #{@new_value.errors.full_messages.to_sentence}"
    end

    def create_attributes_value!
      attributes = [@primary_attribute, *@extended_attributes]

      attributes.each do |attribute|
        attributes_value = AttributesValue.find_or_create_by(
          related_attribute: attribute,
          value: @new_value,
        )

        next if attributes_value.persisted?

        raise ActiveRecord::Rollback,
          "Failed to link value to attribute: #{attributes_value.errors.full_messages.to_sentence}"
      end
    end

    def update_data_files!
      DumpAttributesCommand.new(interactive: true, **params.to_h).execute
      DumpValuesCommand.new(interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["values"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute

      logger.warn(
        "Attribute has custom sorting, please ensure your new value is in the right position in data/attributes.yml",
      ) if @primary_attribute.manually_sorted?
    end
  end
end
