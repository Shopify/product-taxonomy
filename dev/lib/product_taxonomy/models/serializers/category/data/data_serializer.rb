# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        module DataSerializer
          class << self
            def serialize_all(root = nil)
              categories = root ? root.descendants_and_self : ProductTaxonomy::Category.all_depth_first
              categories.sort_by(&:id_parts).flat_map { serialize(_1) }
            end

            # @param [Category] category
            # @return [Hash]
            def serialize(category)
              return_reason_ids = category.return_reasons.map(&:friendly_id)
              special_reasons = return_reason_ids.select { |r| ['unknown', 'other'].include?(r) }
              regular_reasons = return_reason_ids.reject { |r| ['unknown', 'other'].include?(r) }
              sorted_return_reasons = AlphanumericSorter.sort(regular_reasons) + 
                                     (special_reasons.include?('unknown') ? ['unknown'] : []) +
                                     (special_reasons.include?('other') ? ['other'] : [])
              
              {
                "id" => category.id,
                "name" => category.name,
                "children" => category.children.sort_by(&:id_parts).map(&:id),
                "attributes" => AlphanumericSorter.sort(category.attributes.map(&:friendly_id), other_last: true),
                "return_reasons" => sorted_return_reasons,
              }
            end
          end
        end
      end
    end
  end
end
