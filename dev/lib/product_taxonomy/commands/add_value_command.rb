# frozen_string_literal: true

module ProductTaxonomy
  class AddValueCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @attribute_friendly_id = options[:attribute_friendly_id]
    end

    def execute
      create_value!
      update_data_files!
    end

    private

    def create_value!
      @attribute = Attribute.find_by(friendly_id: @attribute_friendly_id)
      raise "Attribute `#{@attribute_friendly_id}` not found" if @attribute.nil?
      if @attribute.extended?
        raise "Attribute `#{@attribute.name}` is an extended attribute, please use a primary attribute instead"
      end

      friendly_id = IdentifierFormatter.format_friendly_id("#{@attribute.friendly_id}__#{@name}")
      value = Value.create_validate_and_add!(
        id: Value.next_id,
        name: @name,
        friendly_id:,
        handle: IdentifierFormatter.format_handle(friendly_id),
      )
      @attribute.add_value(value)

      logger.info("Created value `#{value.name}` for attribute `#{@attribute.name}`")
    end

    def update_data_files!
      DumpAttributesCommand.new(options).execute
      DumpValuesCommand.new(options).execute
      SyncEnLocalizationsCommand.new(targets: "values").execute
      GenerateDocsCommand.new({}).execute

      logger.warn(
        "Attribute has custom sorting, please ensure your new value is in the right position in data/attributes.yml",
      ) if @attribute.manually_sorted?
    end
  end
end
