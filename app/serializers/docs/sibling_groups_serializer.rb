# frozen_string_literal: true

module Docs
  class SiblingGroupsSerializer
    class << self
      def unpack(hash)
        {
          "id" => hash["id"],
          "name" => hash["name"],
          "fully_qualified_type" => hash["full_name"],
          "depth" => hash["level"],
          "parent_id" => parent_id(hash),
          "node_type" => hash["level"].zero? ? "root" : "leaf",
          "ancestor_ids" => hash["ancestors"].map { _1["id"] }.join(","),
          "attribute_ids" => hash["attributes"].map { _1["id"] }.join(","),
        }
      end

      def unpack_all(data_list)
        data_list.each_with_object({}) do |vertical, groups|
          vertical["categories"].each do |hash|
            groups[hash["level"]] ||= {}
            groups[hash["level"]][parent_id(hash)] ||= []
            groups[hash["level"]][parent_id(hash)] << unpack(hash)
          end
        end
      end

      private

      def parent_id(hash)
        hash["parent_id"].presence || "root"
      end
    end
  end
end
