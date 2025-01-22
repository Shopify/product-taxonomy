# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Attribute
      module Docs
        module ReversedSerializer
          class << self
            def serialize_all
              attributes_to_categories = ProductTaxonomy::Category.all.each_with_object({}) do |category, hash|
                category.attributes.each do |attribute|
                  hash[attribute] ||= []
                  hash[attribute] << category
                end
              end

              serialized_attributes = ProductTaxonomy::Attribute.all.sort_by(&:name).map do |attribute|
                serialize(attribute, attributes_to_categories[attribute])
              end

              {
                "attributes" => serialized_attributes,
              }
            end

            # @param [Attribute] attribute The attribute to serialize.
            # @param [Array<Category>] attribute_categories The categories that the attribute belongs to.
            # @return [Hash] The serialized attribute.
            def serialize(attribute, attribute_categories)
              attribute_categories ||= []
              {
                "id" => attribute.gid,
                "handle" => attribute.handle,
                "name" => attribute.name,
                "base_name" => attribute.extended? ? attribute.base_attribute.name : nil,
                "categories" => attribute_categories.sort_by(&:full_name).map do |category|
                  {
                    "id" => category.gid,
                    "full_name" => category.full_name,
                  }
                end,
                "values" => attribute.sorted_values.map do |value|
                  {
                    "id" => value.gid,
                    "name" => value.name,
                  }
                end,
              }
            end
          end
        end
      end
    end
  end
end
