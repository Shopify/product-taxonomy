# frozen_string_literal: true

class MappingRule < ApplicationRecord
  belongs_to :integration
  belongs_to :input, polymorphic: true
  belongs_to :output, polymorphic: true

  PRESENT = "present"

  class << self
    #
    # `dist/` serialization

    def legacy_as_json(mapping_rules, version:)
      {
        "version" => version,
        "mappings" => mapping_blocks_as_json(mapping_rules),
      }
    end

    private

    # TODO: Make this normative
    def mapping_blocks_as_json(mapping_rules)
      mapping_rule_blocks = Integration.all.pluck(:id, :available_versions).flat_map do |id, versions|
        [id].product(versions, [true, false])
      end.filter_map do |integration_id, version, from_shopify|
        rules = mapping_rules.where(integration_id:, from_shopify:)
        rules = if from_shopify
          rules.where(output_version: version)
        else
          rules.where(input_version: version)
        end
        rules if rules.any?
      end

      mapping_rule_blocks.map do |mapping_rules|
        rules = MappingBuilder.simple_mapping(mapping_rules:)
        {
          "input_taxonomy" => mapping_rules.first.input_version,
          "output_taxonomy" => mapping_rules.first.output_version,
          "rules" => rules&.filter_map { serialize_rule(_1) },
        }
      end
    end

    def serialize_rule(mapping)
      return if mapping.nil?

      if mapping[:input][:attributes].present?
        mapping[:input][:attributes] = mapping[:input][:attributes].map do |attribute|
          {
            name: Attribute.find(attribute[:name]).gid,
            value: attribute[:value].nil? ? nil : Value.find(attribute[:value]).gid,
          }
        end
      end

      {
        "input" => mapping[:input],
        "output" => mapping[:output],
      }
    end
  end

  def apply(output_acc)
    output_hash = output.payload.as_json
    output_hash.delete_if { |_, value| value == [] }
    output_acc.merge(output_hash) do |key, old_val, new_val|
      intersection = old_val.intersection(new_val)
      if !old_val.empty? && intersection.empty?
        raise "Rules conflicted, please review the rules.
          rule: #{as_json}, key: #{key}, old_val: #{old_val}, new_val: #{new_val}"
      end

      intersection
    end
  end

  def match?(product_input)
    rule_input = input

    return false unless product_input[:product_category_id] == rule_input.product_category_id
    return true if rule_input.properties.blank?

    rule_input.properties.all? do |rule_attribute|
      product_input[:attributes].any? do |attribute|
        if attribute[:name] == rule_attribute["name"]
          values_match = attribute[:value] == rule_attribute["value"]
          # TODO: Handle inputs that are lists/multi-selections
          value_included = if rule_attribute["value"].is_a?(Array)
            rule_attribute["value"].include?(attribute[:value])
          else
            false
          end
          value_present = attribute[:value].present? && rule_attribute["value"] == PRESENT

          values_match || value_included || value_present
        else
          false
        end
      end
    end
  end
end
