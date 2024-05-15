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
        "mappings" => integration_blocks.map { |source, target|
          mapping_blocks_as_json(source, target, mapping_rules)
        },
      }
    end

    private

    def integration_blocks
      Integration.all.pluck(:id, :available_versions).flat_map do |id, versions|
        source, destination = where(integration_id: id).pluck(:input_version, :output_version).uniq
      end
    end

    def mapping_blocks_as_json(input_version, output_version, mapping_rules)
      {
        "input_taxonomy" => input_version,
        "output_taxonomy" => output_version,
        "rules" => mapping_rules.select {
          _1.input_version == input_version && _1.output_version == output_version
        }.map(&:rule_as_json),
      }
    end
  end

  def rule_as_json
    resolve_input_attribute_values
    {
      "input" => input.payload.compact,
      "output" => output.payload.compact,
    }
  end

  private

  def resolve_input_attribute_values
    if input.payload[:properties].present?
      input.payload[:properties] = input.payload[:properties].map do |attribute|
        {
          name: Attribute.find(attribute[:name]).gid,
          value: Value.find_by_id(attribute[:value])&.gid,
        }
      end
    end
  end
end
