# frozen_string_literal: true

class MappingRule < ApplicationRecord
  belongs_to :integration
  belongs_to :input, polymorphic: true
  belongs_to :output, polymorphic: true

  PRESENT = "present"

  class << self
    #
    # `dist/` serialization

    def as_json(mapping_rules, version:)
      {
        "version" => version,
        "mappings" => integration_blocks.map do |source, target|
          mapping_blocks_as_json(source, target, mapping_rules)
        end,
      }
    end

    def as_txt(mappings, version:)
      header = <<~HEADER
        # Shopify Product Taxonomy - Mapping #{mappings.first.input_version} to #{mappings.first.output_version}
        # Format:
        # → {base taxonomy category name}
        # ⇒ {mapped taxonomy category name}
      HEADER
      visible_mappings = mappings.filter_map do |mapping|
        next if mapping.input.type == mapping.output.type && mapping.input.full_name == mapping.output.full_name

        mapping.as_txt.presence
      end.sort
      [
        header,
        *visible_mappings,
      ].flatten.join("\n").chomp
    end

    private

    def integration_blocks
      Integration.all.pluck(:id, :available_versions).flat_map do |id, versions|
        _source, _destination = where(integration_id: id).pluck(:input_version, :output_version).uniq
      end
    end

    def mapping_blocks_as_json(input_version, output_version, mapping_rules)
      rules = mapping_rules
        .filter_map { _1.as_json if _1.input_version == input_version && _1.output_version == output_version }
        .compact_blank
      if input_version.include?("shopify")
        rules.sort_by! { Category.id_parts(_1["input"]["category"]["id"]) }
      end
      {
        "input_taxonomy" => input_version,
        "output_taxonomy" => output_version,
        "rules" => rules,
      }
    end
  end

  def as_json
    input_integration_version = input_version unless from_shopify?
    output_integration_version = output_version if from_shopify?

    input_json = input.as_json(integration_version: input_integration_version)
    output_json = output.as_json(integration_version: output_integration_version)

    if input_json.empty? || output_json.empty?
      return {}
    end

    {
      "input" => input_json,
      "output" => output_json,
    }
  end

  def as_txt
    input_text = input.as_txt
    output_text = output.as_txt
    return if input_text.blank? || output_text.blank?

    <<~TEXT
      → #{input_text}
      ⇒ #{output_text}
    TEXT
  end
end
