# frozen_string_literal: true

module ProductTaxonomy
  class Category
    include ActiveModel::Validations

    class << self
      # Load categories from source data.
      #
      # @param source_data [Array<Hash>] The source data to load categories from.
      # @param attributes [Hash<String, Attribute>] The attributes of the categories, keyed by friendly ID.
      # @return Array<Category> The root categories (verticals) of the category tree.
      def load_from_source(source_data:, attributes:)
        model_index = ModelIndex.new(self)

        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        # First pass: Create all nodes and add to model index
        source_data.each do |item|
          node = Category.new(
            id: item["id"],
            name: item["name"],
            attributes: item["attributes"]&.map { attributes[_1] || _1 },
            uniqueness_context: model_index,
          )
          model_index.add(node)
        end

        # Second pass: Build relationships
        nodes_by_id = model_index.hashed_by(:id)
        source_data.each do |item|
          parent = nodes_by_id[item["id"]]
          add_children(type: "children", nodes: nodes_by_id, item:, parent:)
          add_children(type: "secondary_children", nodes: nodes_by_id, item:, parent:)
        end

        # Third pass: Validate all nodes and collect root nodes
        nodes_by_id.values.each_with_object([]) do |node, root_nodes|
          node.validate!
          root_nodes << node if node.root?
        end
      end

      private

      def add_children(type:, nodes:, item:, parent:)
        item[type]&.each do |child_id|
          child = nodes[child_id] || child_id

          case type
          when "children" then parent.add_child(child)
          when "secondary_children" then parent.add_secondary_child(child)
          end
        end
      end
    end

    validates :id, format: { with: /\A[a-z]{2}(-\d+)*\z/ }
    validates :name, presence: true
    validate :id_matches_depth
    validate :id_starts_with_parent_id, unless: :root?
    validate :attributes_found?
    validate :children_found?
    validate :secondary_children_found?
    validates_with ProductTaxonomy::ModelIndex::UniquenessValidator, attributes: [:id]

    attr_reader :id, :name, :children, :secondary_children, :attributes, :uniqueness_context
    attr_accessor :parent, :secondary_parents

    # @param id [String] The ID of the category.
    # @param name [String] The name of the category.
    # @param attributes [Array<Attribute>] The attributes of the category.
    # @param uniqueness_context [ModelIndex] The uniqueness context for the category.
    # @param parent [Category] The parent category of the category.
    def initialize(id:, name:, attributes: [], uniqueness_context: nil, parent: nil)
      @id = id
      @name = name
      @children = []
      @secondary_children = []
      @attributes = attributes
      @parent = parent
      @secondary_parents = []
      @uniqueness_context = uniqueness_context
    end

    #
    # Manipulation
    #

    # Add a child to the category
    #
    # @param [Category|String] child node, or the friendly ID if the node was not found.
    def add_child(child)
      @children << child

      return unless child.is_a?(Category)

      child.parent = self
    end

    # Add a secondary child to the category
    #
    # @param [Category|String] child node, or the friendly ID if the node was not found.
    def add_secondary_child(child)
      @secondary_children << child

      return unless child.is_a?(Category)

      child.secondary_parents << self
    end

    #
    # Information
    #
    def inspect
      "#<#{self.class.name} id=#{id} name=#{name}>"
    end

    # Whether the category is the root category
    #
    # @return [Boolean]
    def root?
      parent.nil?
    end

    # Whether the category is a leaf category
    #
    # @return [Boolean]
    def leaf?
      children.empty?
    end

    # The level of the category
    #
    # @return [Integer]
    def level
      ancestors.size
    end

    # The root category in this category's tree
    #
    # @return [Category]
    def root
      ancestors.last || self
    end

    # The ancestors of the category
    #
    # @return [Array<Category>]
    def ancestors
      if root?
        []
      else
        [parent] + parent.ancestors
      end
    end

    # The full name of the category
    #
    # @return [String]
    def full_name
      return name if root?

      parent.full_name + " > " + name
    end

    # Whether the category is a descendant of another category
    #
    # @param [Category] category
    # @return [Boolean]
    def descendant_of?(category)
      ancestors.include?(category)
    end

    # Iterate over the category and all its descendants
    #
    # @yield [Category]
    def traverse(&block)
      yield self
      children.each { _1.traverse(&block) }
    end

    private

    #
    # Validation
    #
    def id_matches_depth
      parts_count = id.split("-").size

      return if parts_count == level + 1

      if level.zero?
        # In this case, the most likely mistake was not adding the category to the parent's `children` field.
        errors.add(:base, :orphan, message: "\"#{id}\" does not appear in the children of any category")
      else
        errors.add(
          :id,
          :depth_mismatch,
          message: "\"#{id}\" has #{parts_count} #{"part".pluralize(parts_count)} but is at level #{level + 1}",
        )
      end
    end

    def id_starts_with_parent_id
      return if id.start_with?(parent.id)

      errors.add(:id, :prefix_mismatch, message: "\"#{id}\" must be prefixed by \"#{parent.id}\"")
    end

    def attributes_found?
      attributes&.each do |attribute|
        next if attribute.is_a?(Attribute)

        errors.add(
          :attributes,
          :not_found,
          message: "could not be resolved for friendly ID \"#{attribute}\"",
        )
      end
    end

    def children_found?
      children&.each do |child|
        next if child.is_a?(Category)

        errors.add(
          :children,
          :not_found,
          message: "could not be resolved for friendly ID \"#{child}\"",
        )
      end
    end

    def secondary_children_found?
      secondary_children&.each do |child|
        next if child.is_a?(Category)

        errors.add(
          :secondary_children,
          :not_found,
          message: "could not be resolved for friendly ID \"#{child}\"",
        )
      end
    end
  end
end
