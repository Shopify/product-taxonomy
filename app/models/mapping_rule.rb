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
      {
        "input_taxonomy" => input_version,
        "output_taxonomy" => output_version,
        "rules" => mapping_rules.select do
          _1.input_version == input_version && _1.output_version == output_version
        end.map(&:as_json),
      }
    end
  end

  def as_json
    resolve_input_attribute_values!
    {
      "input" => input.payload.except!("properties").compact,
      "output" => output.payload.except!("properties").compact,
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

  private

  def resolve_input_attribute_values!
    if input.payload["properties"].present?
      input.payload["attributes"] = input.payload["properties"].map do |property|
        {
          "attribute" => Attribute.find_by(friendly_id: property["attribute"]).gid,
          "value" => Value.find_by(friendly_id: property["value"])&.gid,
        }
      end
    end
  end
end
