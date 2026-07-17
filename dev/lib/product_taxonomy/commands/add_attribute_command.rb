# frozen_string_literal: true

module ProductTaxonomy
  class AddAttributeCommand < Command
    def initialize(options)
      super
      load_taxonomy
      @name = options[:name]
      @description = options[:description]
      @values = options[:values]
      @type = options[:type].presence || "closed_list"
      @measurement_type = options[:measurement_type]
      @supported_units = options[:supported_units]
      @base_attribute_friendly_id = options[:base_attribute_friendly_id]
    end

    def execute
      if @base_attribute_friendly_id
        create_extended_attribute!
      else
        create_base_attribute!
      end
      update_data_files!
    end

    private

    def create_base_attribute!
      case @type
      when "closed_list"
        create_closed_list_attribute!
      when "measurement"
        create_measurement_attribute!
      else
        raise "Unsupported attribute type `#{@type}`. Supported types are: closed_list, measurement"
      end
    end

    def create_closed_list_attribute!
      raise "Values must be provided when creating a closed-list attribute" if value_names.empty?
      raise "Measurement type should not be provided when creating a closed-list attribute" if @measurement_type.present?
      raise "Supported units should not be provided when creating a closed-list attribute" if supported_unit_names.any?

      @attribute = Attribute.create_validate_and_add!(
        id: Attribute.next_id,
        name: @name,
        description: @description,
        friendly_id:,
        handle:,
        type: "closed_list",
        values: find_or_create_values,
      )
      logger.info("Created closed-list attribute `#{@attribute.name}` with friendly_id=`#{@attribute.friendly_id}`")
    end

    def create_measurement_attribute!
      raise "Values should not be provided when creating a measurement attribute" if value_names.any?
      raise "Measurement type must be provided when creating a measurement attribute" if @measurement_type.blank?
      raise "Supported units must be provided when creating a measurement attribute" if supported_unit_names.empty?

      @attribute = Attribute.create_validate_and_add!(
        id: Attribute.next_id,
        name: @name,
        description: @description,
        friendly_id:,
        handle:,
        type: "measurement",
        measurement_type: @measurement_type,
        supported_units: supported_unit_names,
      )
      logger.info("Created measurement attribute `#{@attribute.name}` with friendly_id=`#{@attribute.friendly_id}`")
    end

    def create_extended_attribute!
      raise "Values should not be provided when creating an extended attribute" if value_names.any?
      raise "Type should not be provided when creating an extended attribute" if @type != "closed_list"
      raise "Measurement type should not be provided when creating an extended attribute" if @measurement_type.present?
      raise "Supported units should not be provided when creating an extended attribute" if supported_unit_names.any?

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
      @values&.split(",")&.map(&:strip)&.reject(&:blank?) || []
    end

    def supported_unit_names
      @supported_unit_names ||= @supported_units&.split(",")&.map(&:strip)&.reject(&:blank?) || []
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
