# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Docs
        module YamlSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Disclosure.all.map { serialize(_1) }
            end

            # @param [Disclosure] disclosure
            # @return [Hash]
            def serialize(disclosure)
              {
                "id" => disclosure.gid,
                "public_id" => disclosure.public_id,
                "name" => disclosure.name,
                "description" => disclosure.description,
                "parent_public_id" => disclosure.parent_public_id,
                "jurisdictions" => disclosure.jurisdictions,
                "legal_citation" => disclosure.legal_citation,
                "title" => disclosure.title,
                "content" => disclosure.content,
                "source" => disclosure.source,
                "symbol" => disclosure.symbol,
                "display_requirements" => disclosure.display_requirements,
                "children" => disclosure.children.map { { "public_id" => _1.public_id, "name" => _1.name } },
              }
            end
          end
        end
      end
    end
  end
end
