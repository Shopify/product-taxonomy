# frozen_string_literal: true

module ProductTaxonomy
  # A legally-required product disclosure (e.g. a safety warning or chemical
  # exposure notice). Disclosures form a shallow hierarchy: grouping/root nodes
  # (no `parent_id`) organize the axis, and leaf nodes carry the jurisdiction
  # and display information that merchants surface.
  class Disclosure
    include ActiveModel::Validations
    extend Indexed

    # Surfaces on which a disclosure may be displayed.
    SURFACES = ["product_page", "cart", "checkout"].freeze

    class << self
      # Load disclosures from source data. By default this is deserialized from
      # `data/disclosures.yml`.
      #
      # @param source_data [Array<Hash>] The source data to load disclosures from.
      # @return [void]
      def load_from_source(source_data)
        raise ArgumentError, "source_data must be an array" unless source_data.is_a?(Array)

        source_data.each do |disclosure_data|
          raise ArgumentError, "source_data must contain hashes" unless disclosure_data.is_a?(Hash)

          disclosure = disclosure_from(disclosure_data)
          Disclosure.add(disclosure)
          disclosure.validate!(:create)
        end
      end

      # Reset all class-level state.
      def reset
        @hashed_models = nil
      end

      private

      def disclosure_from(data)
        Disclosure.new(
          id: data["id"],
          public_id: data["public_id"],
          parent_id: data["parent_id"],
          name: data["name"],
          internal_label: data["internal_label"],
          description: data["description"],
          jurisdictions: data["jurisdictions"],
          legal_citation: data["legal_citation"],
          symbol: data["symbol"],
          display_requirements: data["display_requirements"],
          display_preferences: data["display_preferences"],
          title: data["title"],
          content: data["content"],
          source: data["source"],
          disclosure_attributes: data["disclosure_attributes"],
          disclosure_attribute_values: data["disclosure_attribute_values"],
        )
      end
    end

    validates :id, presence: true, numericality: { only_integer: true }, on: :create
    validates :public_id, presence: true, on: :create
    validates :name, presence: true, on: :create
    validates :internal_label, presence: true, on: :create
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:public_id, :id], on: :create

    # Validations that can only run once the whole axis is loaded.
    validate :parent_reference_exists, on: :taxonomy_loaded
    validate :jurisdiction_and_display_only_on_leaves, on: :taxonomy_loaded
    validate :display_preferences_surfaces_are_valid, on: :taxonomy_loaded

    attr_reader :id, :public_id, :parent_id, :name, :internal_label, :description,
      :jurisdictions, :legal_citation, :symbol, :display_requirements,
      :display_preferences, :title, :content, :source,
      :disclosure_attributes, :disclosure_attribute_values

    def initialize(
      id:,
      public_id:,
      name:,
      internal_label:,
      parent_id: nil,
      description: nil,
      jurisdictions: nil,
      legal_citation: nil,
      symbol: nil,
      display_requirements: nil,
      display_preferences: nil,
      title: nil,
      content: nil,
      source: nil,
      disclosure_attributes: nil,
      disclosure_attribute_values: nil
    )
      @id = id
      @public_id = public_id
      @parent_id = parent_id
      @name = name
      @internal_label = internal_label
      @description = description
      @jurisdictions = jurisdictions
      @legal_citation = legal_citation
      @symbol = symbol
      @display_requirements = display_requirements
      @display_preferences = display_preferences
      @title = title
      @content = content
      @source = source
      @disclosure_attributes = disclosure_attributes
      @disclosure_attribute_values = disclosure_attribute_values
    end

    # The global ID of the disclosure.
    #
    # @return [String]
    def gid
      "gid://shopify/TaxonomyDisclosure/#{id}"
    end

    # Whether this is a grouping/root node (has no parent).
    #
    # @return [Boolean]
    def root?
      parent_id.nil?
    end

    # The parent disclosure, or nil for root nodes.
    #
    # @return [Disclosure, nil]
    def parent
      parent_id && Disclosure.find_by(id: parent_id)
    end

    # The direct children of this disclosure.
    #
    # @return [Array<Disclosure>]
    def children
      Disclosure.all.select { |disclosure| disclosure.parent_id == id }
    end

    # Whether this is a leaf node (no other disclosure points at it). Leaf nodes
    # are the ones that carry jurisdiction and display information.
    #
    # @return [Boolean]
    def leaf?
      children.empty?
    end

    private

    def parent_reference_exists
      return if parent_id.nil?
      return if Disclosure.find_by(id: parent_id)

      errors.add(:parent_id, :not_found, message: "must reference an existing disclosure")
    end

    def jurisdiction_and_display_only_on_leaves
      if leaf?
        errors.add(:jurisdictions, :blank, message: "must be present on leaf disclosures") if jurisdictions.blank?
        if display_preferences.blank?
          errors.add(:display_preferences, :blank, message: "must be present on leaf disclosures")
        end
      else
        errors.add(:jurisdictions, :present, message: "must not be set on grouping disclosures") if jurisdictions.present?
        if display_preferences.present?
          errors.add(:display_preferences, :present, message: "must not be set on grouping disclosures")
        end
      end
    end

    def display_preferences_surfaces_are_valid
      return if display_preferences.blank?

      surfaces = display_preferences.is_a?(Hash) ? display_preferences["surfaces"] : nil
      unless surfaces.is_a?(Array) && surfaces.any?
        errors.add(:display_preferences, :invalid, message: "must define a non-empty surfaces array")
        return
      end

      invalid = surfaces - SURFACES
      errors.add(:display_preferences, :invalid, message: "has invalid surfaces: #{invalid.join(", ")}") if invalid.any?
      errors.add(:display_preferences, :invalid, message: "has duplicate surfaces") if surfaces.uniq.size != surfaces.size
    end
  end
end
