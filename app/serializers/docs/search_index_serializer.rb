# frozen_string_literal: true

require "json"
require "cgi"

module Docs
  class SearchIndexSerializer
    include Singleton

    class << self
      delegate :serialize, to: :instance
    end

    def serialize(category_dist_json)
      return @serialized if @serialized

      search_index = category_dist_json.flat_map do |vertical|
        vertical["categories"].map do |category|
          {
            "title" => category.fetch("full_name"),
            "url" => "?categoryId=#{CGI.escapeURIComponent(category.fetch("id"))}",
            "category" => {
              "id" => category.fetch("id"),
              "name" => category.fetch("name"),
              "fully_qualified_type" => category.fetch("full_name"),
              "depth" => category.fetch("level"),
            },
          }
        end
      end

      @serialized = ::JSON.fast_generate(search_index)
    end
  end
end
