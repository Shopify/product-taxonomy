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
        # Shopify Product Taxonomy - Mappings: #{version}
        # Format:
        # input_taxonomy: <input taxonomy version>
        # output_taxonomy: <output taxonomy version>
        # {full_name} → {full_name}
      HEADER
      sorted_mapping = mappings.sort_by do |mapping|
        mapping.input.full_name.nil? ? 0 : -mapping.input.full_name.size
      end
      padding = sorted_mapping.first.input.full_name.size
      [
        header,
        "input_taxonomy: #{mappings.first.input_version}",
        "output_taxonomy: #{mappings.first.output_version}",
        *mappings.map { _1.as_txt(padding: padding) },
      ].flatten.compact.join("\n")
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

  def as_txt(padding: 0)
    input_text = input.as_txt
    output_text = output.as_txt
    return if input_text.empty? || output_text.empty?

    "#{input_text.ljust(padding)} → #{output_text}"
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
