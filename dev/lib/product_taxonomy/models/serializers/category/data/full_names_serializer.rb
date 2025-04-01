# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        module FullNamesSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Category.all.sort_by(&:full_name).map { serialize(_1) }
            end

            # @param [Category] category
            # @return [Hash]
            def serialize(category)
              {
                "id" => category.id,
                "full_name" => category.full_name,
              }
            end
          end
        end
      end
    end
  end
end
