# typed: strict
# frozen_string_literal: true

module ProductTaxonomy
  class Attribute
    extend T::Sig

    sig { returns(T.nilable(Integer)) }
    attr_reader :id

    sig { returns(String) }
    attr_reader :name, :description, :friendly_id, :handle

    sig { returns(T::Array[Value]) }
    attr_reader :values

    sig do
      params(
        id: T.nilable(Integer),
        name: String,
        description: String,
        friendly_id: String,
        handle: String,
        values: T::Array[Value],
      ).void
    end
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
