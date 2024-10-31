# frozen_string_literal: true

module ProductTaxonomy
  class Category
    include ActiveModel::Validations

    class << self
      def load_from_source(attributes:, file:)
        categories = YAML.safe_load_file(file)
        build_tree(categories:, attributes:)
      end

      def build_tree(categories:, attributes:)
        nodes = {}

        # First pass: Create all nodes
        categories.each do |item|
          node = Category.new(
            id: item["id"],
            name: item["name"],
            attributes: item["attributes"]&.map { attributes[_1] },
          )
          nodes[item["id"]] = node
        end

        # Second pass: Build relationships
        categories.each do |item|
          parent = nodes[item["id"]]
          item["children"]&.each do |child_id|
            child = nodes[child_id]
            parent.add_child(child) if child
          end
        end

        nodes[categories.first["id"]]
      end
    end

    attr_reader :id, :name, :children, :attributes
    attr_accessor :parent

    ID_REGEX = /\A[a-z]{2}(-\d+)*\z/
    validates :id,
      presence: { strict: true },
      format: { with: ID_REGEX }
    validates :name,
      presence: { strict: true }
    validate :id_matches_depth
    validate :id_starts_with_parent_id,
      unless: :root?
    validate :validate_children

    def initialize(id:, name:, attributes: [], parent: nil)
      @id = id
      @name = name
      @children = []
      @attributes = attributes
      @parent = nil
    end

    def add_child(child)
      @children << child
      child.parent = self
    end

    def to_s
      result = "#{id}: #{name}"
      children.each do |child|
        result += "\n#{child}"
      end
      result
    end

    def inspect
      "#<#{self.class.name} id=#{id} name=#{name}>"
    end

    def root?
      parent.nil?
    end

    def leaf?
      children.empty?
    end

    def level
      ancestors.size
    end

    def root
      ancestors.last || self
    end

    def ancestors
      if root?
        []
      else
        [parent] + parent.ancestors
      end
    end

    def id_matches_depth
      return if id.count("-") == level

      errors.add(:id, "#{id} must have #{level + 1} parts")
    end

    def id_starts_with_parent_id
      return if id.start_with?(parent.id)

      errors.add(:id, "#{id} must be prefixed by parent_id=#{parent.id}")
    end

    def validate_children
      children.each do |child|
        unless child.valid?
          errors.add(:children, child.errors.full_messages.join("\n"))
        end
      end
    end
  end
end
