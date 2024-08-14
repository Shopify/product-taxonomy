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
        setup!
        create_value!
        update_data_files!
      end
    end

    private

    def setup!
      @primary_attribute = Attribute.find_by(friendly_id: params[:attribute_friendly_id])

      if @primary_attribute.nil?
        logger.fatal("Primary attribute `#{params[:attribute_friendly_id]}` not found")
        exit(1)
      end

      @extended_attributes = @primary_attribute.extended_attributes
    end

    def create_value!
      Value.find_or_create_for_attribute!(@primary_attribute, params[:name])
    rescue => e
      logger.fatal("Failed to create value: #{e.message}")
      exit(1)
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
