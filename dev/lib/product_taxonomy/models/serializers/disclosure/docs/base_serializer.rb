# frozen_string_literal: true

module ProductTaxonomy
  module Serializers
    module Disclosure
      module Docs
        module BaseSerializer
          class << self
            def serialize_all
              ProductTaxonomy::Disclosure.all.map { serialize(_1) }
            end

            # @param [Disclosure] disclosure
            # @return [Hash]
            def serialize(disclosure)
              parent = disclosure.parent
              {
                "id" => disclosure.gid,
                "public_id" => disclosure.public_id,
                "name" => disclosure.name,
                "description" => disclosure.description,
                "kind" => kind(disclosure),
                "parent_public_id" => parent&.public_id,
                "parent_name" => parent&.name,
                "jurisdictions" => disclosure.jurisdictions,
                "legal_citation" => disclosure.legal_citation,
              }
            end

            private

            # Every leaf must carry display preferences, so a leaf is always displayed.
            def kind(disclosure)
              disclosure.leaf? ? "display" : "grouping"
            end
          end
        end
      end
    end
  end
end
