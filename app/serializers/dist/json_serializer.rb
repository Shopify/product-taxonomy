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
        parent_id: property.parent&.gid,
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
      mapping_rule_blocks = Integration.all.pluck(:id, :available_versions).flat_map do |id, versions|
        [id].product(versions, [true, false])
      end.filter_map do |integration_id, version, from_shopify|
        rules = if from_shopify
          @mapping_rules.where(integration_id:, from_shopify: true, output_version: version)
        else
          @mapping_rules.where(integration_id:, from_shopify: false, input_version: version)
        end
        rules if rules.any?
      end

      mapping_blocks = mapping_rule_blocks.map do |mapping_rules|
        rules = MappingBuilder.simple_mapping(mapping_rules:)
        {
          input_taxonomy: mapping_rules.first.input_version,
          output_taxonomy: mapping_rules.first.output_version,
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
