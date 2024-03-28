# frozen_string_literal: true

module Dist
  class JSONSerializer
    def initialize(verticals:, properties:, mapping_rules:, version:)
      @verticals = verticals
      @properties = properties
      @mapping_rules = mapping_rules
      @version = version
    end

    def taxonomy
      output = {
        version: @version,
        verticals: @verticals.map(&method(:serialize_vertical)),
        attributes: @properties.map(&method(:serialize_property)),
      }
      ::JSON.pretty_generate(output)
    end

    def categories
      output = {
        version: @version,
        verticals: @verticals.map(&method(:serialize_vertical)),
      }
      ::JSON.pretty_generate(output)
    end

    def attributes
      output = {
        version: @version,
        attributes: @properties.map(&method(:serialize_property)),
      }
      ::JSON.pretty_generate(output)
    end

    def mappings
      output = {
        version: @version,
        mappings: build_mapping_blocks.map(&method(:serialize_mapping_block)),
      }
      ::JSON.pretty_generate(output)
    end

    private

    def serialize_vertical(vertical)
      {
        name: vertical.name,
        prefix: vertical.id.downcase,
        categories: vertical.descendants_and_self.map(&method(:serialize_category)),
      }
    end

    def serialize_category(category)
      {
        id: category.gid,
        level: category.level,
        name: category.name,
        full_name: category.full_name,
        parent_id: category.parent&.gid,
        attributes: category.properties.map(&method(:serialize_nested)),
        children: category.children.map(&method(:serialize_nested)),
        ancestors: category.ancestors.map(&method(:serialize_nested)),
      }
    end

    def serialize_property(property)
      {
        id: property.gid,
        name: property.name,
        values: property.property_values.map(&method(:serialize_nested)),
      }
    end

    def serialize_nested(connection)
      {
        id: connection.gid,
        name: connection.name,
      }
    end

    def build_mapping_blocks
      mapping_rule_blocks = Integration.all.flat_map do |integration|
        [true, false].filter_map do |from_shopify|
          rules = @mapping_rules.where(integration:, from_shopify:)
          rules if rules.any?
        end
      end

      mapping_blocks = mapping_rule_blocks.map do |mapping_rules|
        rules = Category.verticals.flat_map do |vertical|
          MappingBuilder.build_category_to_category_mappings_for_vertical(mapping_rules:, vertical:)
        end
        from_shopify = mapping_rules.first.from_shopify
        integration = mapping_rules.first.integration
        {
          input_taxonomy: from_shopify ? "shopify/v1" : "#{integration.name}/v1",
          output_taxonomy: from_shopify ? "#{integration.name}/v1" : "shopify/v1",
          rules:,
        }
      end
      mapping_blocks
    end

    def serialize_mapping_block(mapping_block)
      {
        input_taxonomy: mapping_block[:input_taxonomy],
        output_taxonomy: mapping_block[:output_taxonomy],
        rules: mapping_block[:rules]&.filter_map(&method(:serialize_mapping)),
      }
    end

    def serialize_mapping(mapping)
      return if mapping.nil?

      mapping[:input][:product_category_id] = Category.find(mapping[:input][:product_category_id]).gid
      if mapping[:input][:attributes].present?
        mapping[:input][:attributes] = mapping[:input][:attributes].map do |attribute|
          {
            name: Property.find(attribute[:name]).gid,
            value: attribute[:value].nil? ? nil : PropertyValue.find(attribute[:value]).gid,
          }
        end
      end
      {
        input: mapping[:input],
        output: mapping[:output],
      }
    end
  end
end
