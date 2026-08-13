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
              {
                "id" => category.id,
                "name" => category.name,
                "children" => category.children.sort_by(&:id_parts).map(&:id),
                "attributes" => AlphanumericSorter.sort(category.attributes.map(&:friendly_id), other_last: true),
                "return_reasons" => serialize_return_reasons(category),
              }
            end

            private

            # Inheriting categories round-trip as the literal `inherit`; defining categories keep their curated order
            # from `data/categories/*.yml`, with the catch-all reasons pulled out and appended.
            def serialize_return_reasons(category)
              return "inherit" if category.inherits_return_reasons

              return_reason_ids = category.return_reasons.map(&:friendly_id)
              has_unknown = return_reason_ids.delete("unknown")
              has_other = return_reason_ids.delete("other_reason")
              return_reason_ids << "unknown" if has_unknown
              return_reason_ids << "other_reason" if has_other
              return_reason_ids
            end
          end
        end
      end
    end
  end
end
