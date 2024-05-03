# frozen_string_literal: true

module Docs
  class SearchIndexSerializer
    class << self
      def unpack(hash)
        {
          "title" => hash["full_name"],
          "url" => "?categoryId=#{CGI.escapeURIComponent(hash["id"])}",
          "category" => {
            "id" => hash["id"],
            "name" => hash["name"],
            "fully_qualified_type" => hash["full_name"],
            "depth" => hash["level"],
          },
        }
      end

      def unpack_all(data_list)
        data_list.flat_map do |vertical|
          vertical["categories"].map { unpack(_1) }
        end
      end
    end
  end
end
