# frozen_string_literal: true

module ProductTaxonomy
  class Category
    include ActiveModel::Validations
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
          node = Category.new(
            id: item["id"],
            name: item["name"],
            attributes: Array(item["attributes"]).map { Attribute.find_by(friendly_id: _1) || _1 },
          )
          Category.add(node)
        end

        # Second pass: Build relationships
        source_data.each do |item|
          parent = Category.find_by(id: item["id"])
          add_children(type: "children", item:, parent:)
          add_children(type: "secondary_children", item:, parent:)
        end

        # Third pass: Validate all nodes, sort contents, and collect root nodes for verticals
        @verticals = Category.all.each_with_object([]) do |node, root_nodes|
          node.validate!
          node.children.sort_by!(&:name)
          node.attributes.sort_by!(&:name)
          root_nodes << node if node.root?
        end
        @verticals.sort_by!(&:name)
      end

      # Get the JSON representation of all verticals.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @return [Hash] The JSON representation of all verticals.
      def to_json(version:, locale: "en")
        {
          "version" => version,
          "verticals" => verticals.map do
            {
              "name" => _1.name(locale:),
              "prefix" => _1.id,
              "categories" => _1.descendants_and_self.map { |category| category.to_json(locale:) },
            }
          end,
        }
      end

      # Get the TXT representation of all verticals.
      #
      # @param version [String] The version of the taxonomy.
      # @param locale [String] The locale to use for localized attributes.
      # @param padding [Integer] The padding to use for the GID. Defaults to the length of the longest GID.
      # @return [String] The TXT representation of all verticals.
      def to_txt(version:, locale: "en", padding: longest_gid_length)
        header = <<~HEADER
          # Shopify Product Taxonomy - Categories: #{version}
          # Format: {GID} : {Ancestor name} > ... > {Category name}
        HEADER
        [
          header,
          *all_depth_first.map { _1.to_txt(padding:, locale:) },
        ].join("\n")
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

      def add_children(type:, item:, parent:)
        item[type]&.each do |child_id|
          child = Category.find_by(id: child_id) || child_id

          case type
          when "children" then parent.add_child(child)
          when "secondary_children" then parent.add_secondary_child(child)
          end
        end
      end

      def longest_gid_length
        all.max_by { _1.gid.length }.gid.length
      end
    end

    validates :id, format: { with: /\A[a-z]{2}(-\d+)*\z/ }
    validates :name, presence: true
    validate :id_matches_depth
    validate :id_starts_with_parent_id, unless: :root?
    validate :attributes_found?
    validate :children_found?
    validate :secondary_children_found?
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:id]

    localized_attr_reader :name, keyed_by: :id

    attr_reader :id, :children, :secondary_children, :attributes
    attr_accessor :parent, :secondary_parents

    # @param id [String] The ID of the category.
    # @param name [String] The name of the category.
    # @param attributes [Array<Attribute>] The attributes of the category.
    # @param parent [Category] The parent category of the category.
    def initialize(id:, name:, attributes: [], parent: nil)
      @id = id
      @name = name
      @children = []
      @secondary_children = []
      @attributes = attributes
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

    #
    # Serialization
    #

    def to_json(locale: "en")
      {
        "id" => gid,
        "level" => level,
        "name" => name(locale:),
        "full_name" => full_name(locale:),
        "parent_id" => parent&.gid,
        "attributes" => attributes.map do
          {
            "id" => _1.gid,
            "name" => _1.name(locale:),
            "handle" => _1.handle,
            "description" => _1.description(locale:),
            "extended" => _1.is_a?(ExtendedAttribute),
          }
        end,
        "children" => children.map do
          {
            "id" => _1.gid,
            "name" => _1.name(locale:),
          }
        end,
        "ancestors" => ancestors.map do
          {
            "id" => _1.gid,
            "name" => _1.name(locale:),
          }
        end,
      }
    end

    def to_txt(padding: 0, locale: "en")
      "#{gid.ljust(padding)} : #{full_name(locale:)}"
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
