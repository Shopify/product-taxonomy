# frozen_string_literal: true

module ProductTaxonomy
  class AddAttributeCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @description = options[:description]
      @values = options[:values]
      @base_attribute_friendly_id = options[:base_attribute_friendly_id]
    end

    def execute
      if @base_attribute_friendly_id
        create_extended_attribute!
      else
        create_base_attribute_with_values!
      end
      update_data_files!
    end

    private

    def create_base_attribute_with_values!
      raise "Values must be provided when creating a base attribute" if value_names.empty?

      @attribute = Attribute.create_validate_and_add!(
        id: Attribute.next_id,
        name: @name,
        description: @description,
        friendly_id:,
        handle:,
        values: find_or_create_values,
      )
      logger.info("Created base attribute `#{@attribute.name}` with friendly_id=`#{@attribute.friendly_id}`")
    end

    def create_extended_attribute!
      raise "Values should not be provided when creating an extended attribute" if value_names.any?

      @attribute = ExtendedAttribute.create_validate_and_add!(
        name: @name,
        description: @description,
        friendly_id:,
        handle:,
        values_from: Attribute.find_by(friendly_id: @base_attribute_friendly_id) || @base_attribute_friendly_id,
      )
      logger.info("Created extended attribute `#{@attribute.name}` with friendly_id=`#{@attribute.friendly_id}`")
    end

    def update_data_files!
      DumpAttributesCommand.new({}).execute
      DumpValuesCommand.new({}).execute
      SyncEnLocalizationsCommand.new(targets: "attributes,values").execute
      GenerateDocsCommand.new({}).execute
    end

    def friendly_id
      @friendly_id ||= IdentifierFormatter.format_friendly_id(@name)
    end

    def handle
      @handle ||= IdentifierFormatter.format_handle(friendly_id)
    end

    def value_names
      @values&.split(",")&.map(&:strip) || []
    end

    def find_or_create_values
      value_names.map do |value_name|
        value_friendly_id = IdentifierFormatter.format_friendly_id("#{friendly_id}__#{value_name}")
        existing_value = Value.find_by(friendly_id: value_friendly_id)
        next existing_value if existing_value

        Value.create_validate_and_add!(
          id: Value.next_id,
          name: value_name,
          friendly_id: value_friendly_id,
          handle: IdentifierFormatter.format_handle(value_friendly_id),
        )
      end
    end
  end
end
