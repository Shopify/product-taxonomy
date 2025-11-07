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
              has_unknown = return_reason_ids.delete('unknown')
              has_other = return_reason_ids.delete('other')

              sorted_return_reasons = AlphanumericSorter.sort(return_reason_ids)
              sorted_return_reasons += ['unknown'] if has_unknown
              sorted_return_reasons += ['other'] if has_other
              
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
