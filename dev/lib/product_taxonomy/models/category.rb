# typed: strict
# frozen_string_literal: true

module ProductTaxonomy
  class Category
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :id

    sig { returns(String) }
    attr_reader :name

    sig { returns(T::Array[Attribute]) }
    attr_reader :attributes

    sig { returns(T::Array[Category]) }
    attr_reader :children

    sig { returns(T.nilable(Category)) }
    attr_accessor :parent

    sig { params(id: Integer, name: String, attributes: T::Array[Attribute], parent: T.nilable(Category)).void }
    def initialize(id:, name:, attributes: [], parent: nil)
      @id = id
      @name = name
      @children = T.let([], T::Array[T.untyped])
      @attributes = attributes
      @parent = T.let(nil, T.nilable(Category))
    end
  end
end
