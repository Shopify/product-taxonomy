# typed: strict
# frozen_string_literal: true

module ProductTaxonomy
  class ExtendedAttribute < Attribute
    extend T::Sig
    sig do
      params(
        name: String,
        handle: String,
        description: String,
        friendly_id: String,
        values_from: Attribute,
      ).void
    end
    def initialize(name:, handle:, description:, friendly_id:, values_from:)
      super(
        id: nil,
        name: name,
        handle: handle,
        description: description,
        friendly_id: friendly_id,
        values: values_from.values
      )
    end
  end
end
