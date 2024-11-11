# frozen_string_literal: true

module ProductTaxonomy
  class Value
    attr_reader :id, :name, :friendly_id, :handle

    def initialize(id:, name:, friendly_id:, handle:)
      @id = id
      @name = name
      @friendly_id = friendly_id
      @handle = handle
    end
  end
end
