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
              }
            end
          end
        end
      end
    end
  end
end
