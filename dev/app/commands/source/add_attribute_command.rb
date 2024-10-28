# frozen_string_literal: true

module Source
  class AddAttributeCommand < ApplicationCommand
    usage do
      no_command
    end

    keyword :name do
      desc "Name for the new attribute"
      required
    end

    keyword :description do
      desc "Description for the new attribute"
      required
    end

    option :values do
      long "--values string"
      desc "A comma separated list of values to add to the attribute"
    end

    option :base_attribute_friendly_id do
      long "--base_attribute_friendly_id string"
      short "-base string"
      desc "Friendly ID of the base attribute to extend"
    end

    def execute
      frame("Adding new attribute") do
        setup!
        create_attribute!
        update_data_files!
      end
    end

    private

    def setup!
      if params[:base_attribute_friendly_id]
        if value_names.any?
          logger.fatal("Values are not allowed for extended attributes")
          exit(1)
        end
        @base_attribute = Attribute.find_by(friendly_id: params[:base_attribute_friendly_id])
        if @base_attribute.nil?
          logger.fatal("Base attribute `#{params[:base_attribute_friendly_id]}` not found")
          exit(1)
        end
      elsif value_names.empty?
        logger.fatal("Values are required for base attributes")
        exit(1)
      end
    end

    def create_attribute!
      @attribute = Attribute.find_or_create!(
        params[:name],
        params[:description],
        base_attribute: @base_attribute,
        value_names: value_names,
      )
    rescue => e
      logger.fatal("Failed to create attribute: #{e.message}")
      exit(1)
    end

    def update_data_files!
      DumpAttributesCommand.new(interactive: true, **params.to_h).execute
      DumpValuesCommand.new(interactive: true, **params.to_h).execute
      SyncEnLocalizationsCommand.new(interactive: true, targets: ["attributes", "values"], **params.to_h).execute
      GenerateDocsCommand.new(interactive: true, **params.to_h).execute
    end

    def value_names
      params[:values]&.split(",")&.map(&:strip) || []
    end
  end
end
