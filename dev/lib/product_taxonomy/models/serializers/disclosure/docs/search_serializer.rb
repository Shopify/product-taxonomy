# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Docs
        module SearchSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Disclosure.all.map { serialize(_1) }
            end

            # @param [Disclosure] disclosure
            # @return [Hash]
            def serialize(disclosure)
              {
                "searchIdentifier" => disclosure.public_id,
                "title" => disclosure.name,
                "url" => "?disclosureId=#{CGI.escapeURIComponent(disclosure.public_id)}",
                "disclosure" => {
                  "public_id" => disclosure.public_id,
                  "name" => disclosure.name,
                  "description" => disclosure.description,
                },
              }
            end
          end
        end
      end
    end
  end
end
