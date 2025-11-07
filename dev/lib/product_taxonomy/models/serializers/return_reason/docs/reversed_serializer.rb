# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module ReturnReason
      module Docs
        module ReversedSerializer
          class << self
            def serialize_all
              return_reasons_to_categories = ProductTaxonomy::Category.all.each_with_object({}) do |category, hash|
                category.return_reasons.each do |return_reason|
                  hash[return_reason] ||= []
                  hash[return_reason] << category
                end
              end

              sorted_return_reasons = ProductTaxonomy::ReturnReason.all.sort_by do |return_reason|
                sort_priority = case return_reason.friendly_id
                when "unknown"
                  1
                when "other"
                  2
                else
                  0
                end
                
                [sort_priority, return_reason.name.downcase, return_reason.id]
              end

              serialized_return_reasons = sorted_return_reasons.map do |return_reason|
                serialize(return_reason, return_reasons_to_categories[return_reason])
              end

              {
                "return_reasons" => serialized_return_reasons,
              }
            end

            # @param [ReturnReason] return_reason The return reason to serialize.
            # @param [Array<Category>] return_reason_categories The categories that the return reason belongs to.
            # @return [Hash] The serialized return reason.
            def serialize(return_reason, return_reason_categories)
              return_reason_categories ||= []
              {
                "id" => return_reason.gid,
                "handle" => return_reason.handle,
                "name" => return_reason.name,
                "description" => return_reason.description,
                "categories" => return_reason_categories.sort_by(&:full_name).map do |category|
                  {
                    "id" => category.gid,
                    "full_name" => category.full_name,
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

