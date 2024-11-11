# frozen_string_literal: true

module ProductTaxonomy
  class Category
    attr_reader :id, :name, :children, :attributes
    attr_accessor :parent

    def initialize(id:, name:, attributes: [], parent: nil)
      @id = id
      @name = name
      @children = []
      @attributes = attributes
      @parent = nil
    end
  end
end
