# frozen_string_literal: true

module Dist
  class JSONSerializer
    def initialize(verticals:, properties:, mapping_rules: nil, version:)
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
        mappings: build_mapping_blocks(@mapping_rules).map(&method(:serialize_mapping_block)),
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

    def build_mapping_blocks(mapping_rules)
      all_mapping_blocks = []
      puts "Generating mappings ..."
      mapping_count = 0
      Integration.all.each do |integration|
        [true, false].each do |from_shopify|
          mapping_rule_block = mapping_rules.where(
            integration_id: integration.id,
            from_shopify: from_shopify,
          )
          next if mapping_rule_block.count.zero?

          mappings = []
          Category.verticals.each do |vertical|
            mappings << MappingBuilder.build_one_to_one_mappings_for_vertical(
              mapping_rules: mapping_rule_block,
              vertical: vertical,
            )
          end
          processed_mappings = mappings.flatten.compact
          mapping_count += processed_mappings.count
          all_mapping_blocks << {
            input_taxonomy: "shopify/v1",
            output_taxonomy: "#{integration.name}/v1",
            rules: processed_mappings,
          }
        end
      end
      puts "✓ Generated #{mapping_count} mappings"
      all_mapping_blocks
    end

    def serialize_mapping_block(mapping_block)
      {
        input_taxonomy: mapping_block[:input_taxonomy],
        output_taxonomy: mapping_block[:output_taxonomy],
        rules: mapping_block[:rules]&.map(&method(:serialize_mapping)),
      }
    end

    def serialize_mapping(mapping)
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
