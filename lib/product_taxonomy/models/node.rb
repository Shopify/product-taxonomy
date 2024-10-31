module ProductTaxonomy
  class Node
    attr_reader :id, :name, :children, :attributes

    def initialize(id, name, attributes = [])
      @id = id
      @name = name
      @children = []
      @attributes = attributes
    end

    def add_child(child)
      @children << child
    end
  end
end
