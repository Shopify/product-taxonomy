# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    attr_reader :id, :name, :description, :friendly_id, :handle, :values

    def initialize(id:, name:, description:, friendly_id:, handle:, values:)
      @id = id
      @name = name
      @description = description
      @friendly_id = friendly_id
      @handle = handle
      @values = values
    end
  end
end
