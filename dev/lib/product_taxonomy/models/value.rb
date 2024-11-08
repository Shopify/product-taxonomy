# typed: strict
# frozen_string_literal: true

module ProductTaxonomy
  class Value
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :id

    sig { returns(String) }
    attr_reader :name, :friendly_id, :handle

    sig { params(id: Integer, name: String, friendly_id: String, handle: String).void }
    def initialize(id:, name:, friendly_id:, handle:)
      @id = id
      @name = name
      @friendly_id = friendly_id
      @handle = handle
    end
  end
end
