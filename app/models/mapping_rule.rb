# frozen_string_literal: true

class MappingRule < ApplicationRecord
  belongs_to :integration
  belongs_to :input, polymorphic: true
  belongs_to :output, polymorphic: true

  PRESENT = "present"

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
