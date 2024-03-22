# frozen_string_literal: true

class InputProductGenerator
  class << self
    def generate_inputs_for_categories(categories, rules)
      all_inputs = []
      relevant_attributes = rules.flat_map do |rule|
        rule.input.properties&.map { |attribute| attribute["name"] }
      end.uniq

      categories.each do |category|
        category_attributes = category.properties
          .filter { |attribute| relevant_attributes.include?(attribute.id) }
        all_inputs << generate_inputs_from_category(category, category_attributes)
      end

      all_inputs.flatten
    end

    private

    def generate_inputs_from_category(category, relevant_category_attributes)
      # NOTE: Shopify attributes are optional so we need to account for that in the combination
      all_attributes_with_values = []
      relevant_category_attributes.each do |attribute|
        all_attributes_with_values.push(
          attribute.property_values
            .map { |value| [attribute.id, value.id] }
            .append([attribute.id, nil]),
        )
      end

      attribute_combinations = if all_attributes_with_values.present?
        all_attributes_with_values[0].product(*all_attributes_with_values[1..])
      else
        [[]] # Empty attribute set
      end

      attribute_combinations.map do |combination|
        {
          product_category_id: category[:id],
          attributes: combination.map do |e|
            {
              name: e.first,
              value: e.last,
            }
          end,
        }
      end
    end
  end
end
