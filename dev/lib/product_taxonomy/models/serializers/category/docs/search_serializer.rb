# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Docs
        module SearchSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Category.all_depth_first.flat_map { serialize(_1) }
            end

            # @param [Category] category
            # @return [Hash]
            def serialize(category)
              {
                "searchIdentifier" => category.gid,
                "title" => category.full_name,
                "url" => "?categoryId=#{CGI.escapeURIComponent(category.gid)}",
                "category" => {
                  "id" => category.gid,
                  "name" => category.name,
                  "fully_qualified_type" => category.full_name,
                  "depth" => category.level,
                },
              }
            end
          end
        end
      end
    end
  end
end
