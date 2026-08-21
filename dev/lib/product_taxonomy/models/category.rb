# frozen_string_literal: true

module ProductTaxonomy
  class Category
    include ActiveModel::Validations
    include FormattedValidationErrors
    extend Localized
    extend Indexed

    class << self
      attr_reader :verticals

      # Load categories from source data.
      #
      # @param source_data [Array<Hash>] The source data to load categories from.
      def load_from_source(source_data)
        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        # First pass: Create all nodes and add to index
        source_data.each do |item|
          Category.create_validate_and_add!(
            id: item["id"],
            name: item["name"],
            attributes: Array(item["attributes"]).map { Attribute.find_by(friendly_id: _1) || _1 },
            return_reasons: parse_return_reasons(item["return_reasons"]),
          )
        end

        # Second pass: Build relationships
        source_data.each do |item|
          parent = Category.find_by(id: item["id"])
          add_children(type: "children", item:, parent:)
          add_children(type: "secondary_children", item:, parent:)
        end

        # Third pass: Validate all nodes, sort contents, and collect root nodes for verticals
        @verticals = Category.all.each_with_object([]) do |node, root_nodes|
          node.validate!(:category_tree_loaded)
          node.children.sort_by!(&:name)
          node.attributes.sort_by!(&:name)
          # `return_reasons` order is intentionally preserved from `data/categories/*.yml`.
          root_nodes << node if node.root?
        end
        @verticals.sort_by!(&:name)

        # Fourth pass: fall back to the global reasons where a category defines none, then resolve inheritance so
        # that inheriting categories copy their ancestor's final list.
        Category.all.each(&:apply_default_return_reasons)
        Category.all.each(&:resolve_inherited_return_reasons)
      end

      # Reset all class-level state
      def reset
        @localizations = nil
        @hashed_models = nil
        @verticals = nil
      end

      # Get all categories in depth-first order.
      #
      # @return [Array<Category>] The categories in depth-first order.
      def all_depth_first
        verticals.flat_map(&:descendants_and_self)
      end

      private

      # `return_reasons: inherit` in the data marks a category as inheriting; anything else is an explicit list.
      def parse_return_reasons(value)
        return :inherit if value == "inherit"

        Array(value).map { |friendly_id| ReturnReason.find_by(friendly_id:) || friendly_id }
      end

      def add_children(type:, item:, parent:)
        item[type]&.each do |child_id|
          child = Category.find_by(id: child_id) || child_id

          case type
          when "children" then parent.add_child(child)
          when "secondary_children" then parent.add_secondary_child(child)
          end
        end
      end
    end

    # Validations that can be performed as soon as the category is created.
    validates :id, format: { with: /\A[a-z]{2}(-\d+)*\z/ }, on: :create
    validates :name, presence: true, on: :create
    validate :attributes_found?, on: :create
    validate :return_reasons_found?, on: :create
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:id], on: :create

    # Validations that can only be performed after the category tree has been loaded.
    validate :id_matches_depth, on: :category_tree_loaded
    validate :id_starts_with_parent_id, unless: :root?, on: :category_tree_loaded
    validate :children_found?, on: :category_tree_loaded
    validate :secondary_children_found?, on: :category_tree_loaded
    validate :root_does_not_inherit_return_reasons, if: :root?, on: :category_tree_loaded

    localized_attr_reader :name, keyed_by: :id

    attr_reader :id, :children, :secondary_children, :attributes, :return_reasons, :inherits_return_reasons
    attr_accessor :parent, :secondary_parents

    # @param id [String] The ID of the category.
    # @param name [String] The name of the category.
    # @param attributes [Array<Attribute>] The attributes of the category.
    # @param return_reasons [Array<ReturnReason>, :inherit] The return reasons for the category, or `:inherit` to copy
    #   them from the closest ancestor that defines its own.
    # @param parent [Category] The parent category of the category.
    def initialize(id:, name:, attributes: [], return_reasons: [], parent: nil)
      @id = id
      @name = name
      @children = []
      @secondary_children = []
      @attributes = attributes
      @inherits_return_reasons = return_reasons == :inherit
      @return_reasons = @inherits_return_reasons ? [] : return_reasons
      @parent = parent
      @secondary_parents = []
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

    # Add an attribute to the category
    #
    # @param [Attribute] attribute
    def add_attribute(attribute)
      @attributes << attribute
    end

    # Add a return reason to the category. Explicitly adding a reason means the category defines its own reasons
    # rather than inheriting them, so the first add on an inheriting category drops the inherited reasons.
    #
    # @param [ReturnReason] return_reason
    def add_return_reason(return_reason)
      if @inherits_return_reasons
        @inherits_return_reasons = false
        @return_reasons = []
      end
      @return_reasons << return_reason
    end

    # Materialize the global return reasons for a category that defines none of its own, so runtime consumers always
    # get the baseline set. Inheriting categories are skipped; they copy their ancestor's list once it is final.
    def apply_default_return_reasons
      return if inherits_return_reasons || return_reasons.any?

      @return_reasons = ReturnReason.global.dup
    end

    # Copy return reasons from the closest ancestor that defines its own, when this category inherits. No-op for
    # categories that define their own reasons or have no defining ancestor.
    def resolve_inherited_return_reasons
      return unless inherits_return_reasons

      source = ancestors.find { |ancestor| !ancestor.inherits_return_reasons }
      @return_reasons = source.return_reasons.dup if source
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
      return [] if root?

      [parent] + parent.ancestors
    end

    # The full name of the category
    #
    # @return [String]
    def full_name(locale: "en")
      return name(locale:) if root?

      parent.full_name(locale:) + " > " + name(locale:)
    end

    # The global ID of the category
    #
    # @return [String]
    def gid
      "gid://shopify/TaxonomyCategory/#{id}"
    end

    # Split an ID into its parts.
    #
    # @return [Array<String, Integer>] The parts of the ID.
    def id_parts
      parts = id.split("-")
      [parts.first] + parts[1..].map(&:to_i)
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

    # The descendants of the category
    def descendants
      children.flat_map { |child| [child] + child.descendants }
    end

    # The descendants of the category and the category itself
    #
    # @return [Array<Category>]
    def descendants_and_self
      [self] + descendants
    end

    # The friendly name of the category
    #
    # @return [String]
    def friendly_name
      "#{id}_#{IdentifierFormatter.format_friendly_id(name)}"
    end

    # The next child ID for the category
    #
    # @return [String]
    def next_child_id
      largest_child_id = children.map { _1.id.split("-").last.to_i }.max || 0

      "#{id}-#{largest_child_id + 1}"
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
          message: "not found for friendly ID \"#{attribute}\"",
        )
      end
    end

    def return_reasons_found?
      return_reasons&.each do |return_reason|
        next if return_reason.is_a?(ReturnReason)

        errors.add(
          :return_reasons,
          :not_found,
          message: "not found for friendly ID \"#{return_reason}\"",
        )
      end
    end

    def root_does_not_inherit_return_reasons
      return unless inherits_return_reasons

      # A root category has no ancestor to inherit from, so `inherit` cannot be resolved.
      errors.add(:return_reasons, :root_cannot_inherit, message: "cannot be inherited by a root category")
    end

    def children_found?
      children&.each do |child|
        next if child.is_a?(Category)

        errors.add(
          :children,
          :not_found,
          message: "not found for friendly ID \"#{child}\"",
        )
      end
    end

    def secondary_children_found?
      secondary_children&.each do |child|
        next if child.is_a?(Category)

        errors.add(
          :secondary_children,
          :not_found,
          message: "not found for friendly ID \"#{child}\"",
        )
      end
    end
  end
end
