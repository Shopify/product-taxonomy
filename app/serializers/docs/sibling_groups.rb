# frozen_string_literal: true

require "yaml"

module Serializers
  module Docs
    class SiblingGroups
      include Singleton

      class << self
        delegate :serialize, to: :instance
      end

      def serialize(category_dist_json)
        return @serialized if @serialized

        sibling_groups = {}
        category_dist_json.each do |vertical|
          vertical["categories"].each do |category|
            parent_id = category.fetch("parent_id").presence || "root"
            depth = category.fetch("level")

            sibling_groups[depth] ||= {}
            sibling_groups[depth][parent_id] ||= []
            sibling_groups[depth][parent_id] << sibling_group(category, parent_id:, depth:)
          end
        end

        @serialized = sibling_groups.to_yaml(line_width: 1000)
      end

      private

      def sibling_group(category, parent_id:, depth:)
        {
          "id" => category.fetch("id"),
          "name" => category.fetch("name"),
          "fully_qualified_type" => category.fetch("full_name"),
          "depth" => depth,
          "parent_id" => parent_id,
          "node_type" => depth.zero? ? "root" : "leaf",
          "ancestor_ids" => category.fetch("ancestors").map { _1.fetch("id") }.join(","),
          "attribute_ids" => category.fetch("attributes").map { _1.fetch("id") }.join(","),
        }
      end
    end
  end
end
