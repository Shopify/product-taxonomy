# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Category
      module Data
        module LocalizationsSerializer
          class << self
            def serialize_all
              categories = ProductTaxonomy::Category.all_depth_first

              {
                "en" => {
                  "categories" => categories.sort_by(&:id_parts).reduce({}) { _1.merge!(serialize(_2)) },
                },
              }
            end

            # @param [Category] category
            # @return [Hash]
            def serialize(category)
              {
                category.id => {
                  "name" => category.name,
                  "context" => category.full_name,
                },
              }
            end
          end
        end
      end
    end
  end
end
