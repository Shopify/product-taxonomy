# frozen_string_literal: true

module Docs
  class Mappings
    def reverse_shopify_mapping_rules(mappings)
      mappings.each do |mapping|
        if shopify_mapping?(mapping)
          reverse_taxonomy_names(mapping)
          reverse_mapping_rules(mapping)
        end
      end
    end

    def reverse_mapping_rules(mapping)
      mapping["rules"].each do |rule|
        rule["output"]["category"].each_with_index do |output, index|
          if index == 0
            rule["output"] = { "category" => [rule["input"]["category"]] }
            rule["input"] = { "category" => output }
          else
            mapping.push = build_rule(input: output, output: rule["input"]["category"])
          end
        end
      end
    end

    def reverse_taxonomy_names(mapping)
      input = mapping["input_taxonomy"]
      output = mapping["output_taxonomy"]
      mapping["input_taxonomy"] = output
      mapping["output_taxonomy"] = input
    end

    def shopify_mapping?(mapping)
      mapping["output_taxonomy"].include?("shopify")
    end

    def build_rule(input:, output:)
      {
        "input" => { "category" => input },
        "output" => { "category" => [output] },
      }
    end
  end
end
