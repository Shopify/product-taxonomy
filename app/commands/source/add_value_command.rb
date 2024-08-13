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
      @manually_sorted = @primary_attribute.manually_sorted?
    end

    def create_value!
      value_identifier = "#{@primary_attribute.handle}__#{params[:name]}"
      friendly_id = StringTransformer.generate_friendly_id(value_identifier)

      existing_value = Value.find_by(friendly_id: friendly_id)

      raise ActiveRecord::Rollback,
        "Value `#{friendly_id}` already exists" if existing_value

      position = @primary_attribute.values.map(&:position).compact.max + 1 if @manually_sorted

      @new_value = Value
        .create(
          name: params[:name],
          primary_attribute: @primary_attribute,
          friendly_id: friendly_id,
          handle: StringTransformer.generate_handle(friendly_id),
          position: position,
        )

      unless @new_value.persisted?
        raise ActiveRecord::Rollback,
          "Failed to create value: #{@new_value.errors.full_messages.to_sentence}"
      end
    end

    def create_attributes_value!
      attributes = [@primary_attribute, *@extended_attributes]

      attributes.each do |attribute|
        attributes_value = AttributesValue.create(
          related_attribute: attribute,
          value: @new_value,
        )

        unless attributes_value.persisted?
          raise ActiveRecord::Rollback,
            "Failed to link value to attribute: #{attributes_value.errors.full_messages.to_sentence}"
        end
      end
    end

    def update_data_files!
      DumpAttributesCommand.new(interactive: true, **params.to_h).execute
      DumpValuesCommand.new(interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["values"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute

      logger.warn(
        "Attribute has custom sorting, please ensure your new value is in the right position in data/attributes.yml",
      ) if @manually_sorted
    end
  end
end
