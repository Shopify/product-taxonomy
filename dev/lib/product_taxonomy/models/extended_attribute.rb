# frozen_string_literal: true

module ProductTaxonomy
  class ExtendedAttribute < Attribute
    def initialize(name:, handle:, description:, friendly_id:, values_from:)
      super(
        id: nil,
        name: name,
        handle: handle,
        description: description,
        friendly_id: friendly_id,
        values: values_from&.values
      )
    end
  end
end
