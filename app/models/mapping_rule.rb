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

    private

    def integration_blocks
      Integration.all.pluck(:id, :available_versions).flat_map do |id, versions|
        _source, _destination = where(integration_id: id).pluck(:input_version, :output_version).uniq
      end
    end

    def mapping_blocks_as_json(input_version, output_version, mapping_rules)chann
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
    resolve_input_product_data!
    resolve_output_product_data!
    {
      "input" => input.payload.except!("properties").compact,
      "output" => output.payload.except!("properties").compact,
    }
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

  def full_name(category_id:, for_current_shopify_version: false)
    category_id = category_id.split("/").last
    if for_current_shopify_version
      Category.find(category_id).full_name
    else
      full_name_map(version: output_version)[category_id]
    end
  end

  def full_name_map(version:)
    @full_name_map ||= YAML.load_file(File.join(Rails.root, "data/integrations/#{version}/full_names.yml"))
  end

  def resolve_input_product_data!
    input.payload["product"] = {
      "category_id" => input.payload["product_category_id"],
      "full_name" => full_name(
        category_id: input.payload["product_category_id"],
        for_current_shopify_version: from_shopify?
        ),
      }
    input.payload.except!("product_category_id")
  end

  def resolve_output_product_data!
    output.payload["product"] = output.payload["product_category_id"].map do |category_id|
      {
        "category_id" => category_id,
        "full_name" => full_name(category_id: category_id, for_current_shopify_version: !from_shopify?),
      }
    end
    output.payload.except!("product_category_id")
  end
end
