# frozen_string_literal: true

module ProductTaxonomy
  # A legally-required product disclosure (e.g. a safety warning or chemical
  # exposure notice). Disclosures form a shallow hierarchy: grouping/root nodes
  # (no `parent_public_id`) organize the axis, and leaf nodes carry the
  # jurisdiction and display information that merchants surface.
  class Disclosure
    include ActiveModel::Validations
    include FormattedValidationErrors
    extend Localized
    extend Indexed

    # Surfaces on which a disclosure may be displayed.
    SURFACES = ["product_page", "cart", "checkout"].freeze

    # `public_id` must be a lowercase slug: alphanumeric segments joined by `-` or `_`.
    PUBLIC_ID_FORMAT = /\A[a-z0-9]+(?:[_-][a-z0-9]+)*\z/

    # String-typed fields validated for type on load.
    STRING_FIELDS = [
      :name,
      :internal_label,
      :description,
      :legal_citation,
      :symbol,
      :display_requirements,
      :title,
      :content,
      :source,
    ].freeze

    # Fields required on leaf disclosures (in addition to jurisdictions and display_preferences).
    LEAF_REQUIRED_FIELDS = [:title, :content, :legal_citation, :source].freeze

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
        @localizations = nil
        @hashed_models = nil
      end

      private

      def disclosure_from(data)
        Disclosure.new(
          public_id: data["public_id"],
          parent_public_id: data["parent_public_id"],
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

    validates :public_id, presence: true, format: { with: PUBLIC_ID_FORMAT, allow_blank: true }, on: :create
    validates :name, presence: true, on: :create
    validates :internal_label, presence: true, on: :create
    validates_with ProductTaxonomy::Indexed::UniquenessValidator, attributes: [:public_id], on: :create
    validate :field_types_are_valid, on: :create
    validate :not_self_parenting, on: :create

    # Validations that can only run once the whole axis is loaded.
    validate :parent_reference_exists, on: :taxonomy_loaded
    validate :hierarchy_is_shallow_and_acyclic, on: :taxonomy_loaded
    validate :jurisdiction_and_display_only_on_leaves, on: :taxonomy_loaded
    validate :leaf_required_fields_present, on: :taxonomy_loaded
    validate :display_preferences_surfaces_are_valid, on: :taxonomy_loaded

    localized_attr_reader :name, :description, :title, :content, keyed_by: :public_id

    attr_reader :public_id,
      :parent_public_id,
      :internal_label,
      :jurisdictions,
      :legal_citation,
      :symbol,
      :display_requirements,
      :display_preferences,
      :source,
      :disclosure_attributes,
      :disclosure_attribute_values

    def initialize(
      public_id:,
      name:,
      internal_label:,
      parent_public_id: nil,
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
      @public_id = public_id
      @parent_public_id = parent_public_id
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
      "gid://shopify/TaxonomyDisclosure/#{public_id}"
    end

    # Whether this is a grouping/root node (has no parent).
    #
    # @return [Boolean]
    def root?
      parent_public_id.nil?
    end

    # The parent disclosure, or nil for root nodes.
    #
    # @return [Disclosure, nil]
    def parent
      parent_public_id && Disclosure.find_by(public_id: parent_public_id)
    end

    # The direct children of this disclosure.
    #
    # @return [Array<Disclosure>]
    def children
      Disclosure.all.select { |disclosure| disclosure.parent_public_id == public_id }
    end

    # Whether this is a leaf node (no other disclosure points at it). Leaf nodes
    # are the ones that carry jurisdiction and display information.
    #
    # @return [Boolean]
    def leaf?
      children.empty?
    end

    private

    def field_types_are_valid
      errors.add(:jurisdictions, :invalid, message: "must be an array") if jurisdictions && !jurisdictions.is_a?(Array)
      errors.add(:display_preferences, :invalid, message: "must be a hash") if display_preferences && !display_preferences.is_a?(Hash)
      unless disclosure_attributes.nil? || disclosure_attributes.is_a?(Array)
        errors.add(:disclosure_attributes, :invalid, message: "must be an array")
      end
      unless disclosure_attribute_values.nil? || disclosure_attribute_values.is_a?(Array)
        errors.add(:disclosure_attribute_values, :invalid, message: "must be an array")
      end
      STRING_FIELDS.each do |field|
        value = send(field)
        errors.add(field, :invalid, message: "must be a string") if value && !value.is_a?(String)
      end
    end

    def not_self_parenting
      return if parent_public_id.nil?

      errors.add(:parent_public_id, :invalid, message: "cannot be its own parent") if parent_public_id == public_id
    end

    def parent_reference_exists
      return if parent_public_id.nil?
      return if Disclosure.find_by(public_id: parent_public_id)

      errors.add(:parent_public_id, :not_found, message: "must reference an existing disclosure")
    end

    # Enforces a two-level axis (grouping/root → leaf) and guards against cycles.
    def hierarchy_is_shallow_and_acyclic
      return if parent_public_id.nil?

      seen = [public_id]
      current = Disclosure.find_by(public_id: parent_public_id)
      while current
        if seen.include?(current.public_id)
          errors.add(:parent_public_id, :invalid, message: "introduces a cycle in the hierarchy")
          return
        end
        seen << current.public_id
        current = current.parent_public_id && Disclosure.find_by(public_id: current.parent_public_id)
      end

      parent = Disclosure.find_by(public_id: parent_public_id)
      unless parent.nil? || parent.root?
        errors.add(:parent_public_id, :invalid, message: "must reference a top-level grouping (max depth is two levels)")
      end
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

    def leaf_required_fields_present
      return unless leaf?

      LEAF_REQUIRED_FIELDS.each do |field|
        errors.add(field, :blank, message: "must be present on leaf disclosures") if send(field).blank?
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
