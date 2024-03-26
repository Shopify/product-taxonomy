# frozen_string_literal: true

class MappingBuilder
  class << self
    def build_one_to_one_mappings_for_vertical(mapping_rules:, vertical:)
      relevant_rules = mapping_rules.select { |rule| rule.input.product_category_id.start_with?(vertical.id) }
      relevant_rules.map do |rule|
        {
          input: rule.input.payload.delete_if { |_k, v| v.nil? },
          output: rule.output.payload.delete_if { |_k, v| v.nil? },
        }
      end
    end

    def build_mappings_for_vertical(mapping_rules:, vertical:)
      puts " → for #{Integration.find(mapping_rules.first.integration_id).name} in #{vertical.name}..."
      relevant_rules = mapping_rules.select { |rule| rule.input.product_category_id.start_with?(vertical.id) }
      return if relevant_rules.count.zero?

      inputs = InputProductGenerator.generate_inputs_for_categories(vertical.descendants_and_self, relevant_rules)

      build_mappings_from_inputs_and_rules(inputs, relevant_rules)
    end

    private

    def build_mappings_from_inputs_and_rules(inputs, rules)
      inputs.map do |input|
        mapping = {
          input: input,
          output: rules.filter { |rule| rule.match?(input) }.reduce({}) do |final_output, rule|
            rule.apply(final_output)
          end,
        }

        if mapping[:output].empty?
          nil
        elsif mapping[:input][:attributes].empty?
          mapping[:input].delete(:attributes)
          mapping
        else
          mapping
        end
      end
    end
  end
end
