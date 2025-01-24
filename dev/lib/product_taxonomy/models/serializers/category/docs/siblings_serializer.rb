# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Docs
        module SiblingsSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Category.all_depth_first.each_with_object({}) do |category, groups|
                parent_id = category.parent&.gid.presence || "root"
                sibling = serialize(category)

                groups[category.level] ||= {}
                groups[category.level][parent_id] ||= []
                groups[category.level][parent_id] << sibling
              end
            end

            # @param [Category] category
            # @return [Hash]
            def serialize(category)
              {
                "id" => category.gid,
                "name" => category.name,
                "fully_qualified_type" => category.full_name,
                "depth" => category.level,
                "parent_id" => category.parent&.gid.presence || "root",
                "node_type" => category.root? ? "root" : "leaf",
                "ancestor_ids" => category.ancestors.map(&:gid).join(","),
                "attribute_handles" => category.attributes.map(&:handle).join(","),
              }
            end
          end
        end
      end
    end
  end
end
