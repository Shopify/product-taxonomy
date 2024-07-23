# frozen_string_literal: true

class Category < ApplicationRecord
  default_scope { order(:name) }

  scope :verticals, -> { where(parent_id: nil) }

  belongs_to :parent, class_name: "Category", optional: true

  has_many :children, class_name: "Category", inverse_of: :parent
  has_many :categories_attributes,
    dependent: :destroy,
    foreign_key: :category_id,
    primary_key: :id,
    inverse_of: :category
  has_many :related_attributes, through: :categories_attributes

  validates :id,
    presence: { strict: true },
    format: { with: /\A[a-z]{2}(-\d+)*\z/ }
  validates :name,
    presence: { strict: true }
  validate :id_matches_depth
  validate :id_starts_with_parent_id,
    unless: :root?
  validates_associated :children

  LOCALIZATION_PATH = "data/localizations/categories/*.yml"

  class << self
    def gid(id)
      "gid://shopify/TaxonomyCategory/#{id}"
    end

    def id_parts(id)
      id.split("-").map { _1 =~ /^\d+$/ ? _1.to_i : _1 }
    end

    def localizations
      @localizations ||= Dir.glob(LOCALIZATION_PATH).each_with_object({}) do |file, localizations|
        locale = File.basename(file, ".yml")
        localizations[locale] = YAML.load_file(file).dig(locale, "categories")
      end
    end

    def find_localization(locale, id, key)
      localizations.dig(locale, id, key)
    end

    #
    # `data/` deserialization

    def new_from_data(data)
      new(row_from_data(data))
    end

    def insert_all_from_data(data, ...)
      insert_all!(Array(data).map { row_from_data(_1) }, ...)
    end

    #
    # `dist/` serialization

    def as_json(verticals, version:, locale: "en")
      {
        "version" => version,
        "verticals" => verticals.map { _1.as_json_with_descendants(locale:) },
      }
    end

    def as_txt(verticals, version:, locale: "en")
      header = <<~HEADER
        # Shopify Product Taxonomy - Categories: #{version}
        # Format: {GID} : {Ancestor name} > ... > {Category name}
      HEADER
      padding = reorder("LENGTH(id) desc").first.gid.size
      [
        header,
        *verticals.flat_map(&:descendants_and_self).map { _1.as_txt(padding:, locale:) },
      ].join("\n")
    end

    #
    # `docs/` parsing

    def as_json_for_docs_siblings(distribution_verticals)
      distribution_verticals.each_with_object({}) do |vertical, groups|
        vertical["categories"].each do |data|
          parent_id = data["parent_id"].presence || "root"
          sibling = {
            "id" => data["id"],
            "name" => data["name"],
            "fully_qualified_type" => data["full_name"],
            "depth" => data["level"],
            "parent_id" => parent_id,
            "node_type" => data["level"].zero? ? "root" : "leaf",
            "ancestor_ids" => data["ancestors"].map { _1["id"] }.join(","),
            "attribute_ids" => data["attributes"].map { _1["id"] }.join(","),
          }

          groups[data["level"]] ||= {}
          groups[data["level"]][parent_id] ||= []
          groups[data["level"]][parent_id] << sibling
        end
      end
    end

    def as_json_for_docs_search(distribution_verticals)
      distribution_verticals.flat_map do |vertical|
        vertical["categories"].map do |data|
          {
            "title" => data["full_name"],
            "url" => "?categoryId=#{CGI.escapeURIComponent(data["id"])}",
            "category" => {
              "id" => data["id"],
              "name" => data["name"],
              "fully_qualified_type" => data["full_name"],
              "depth" => data["level"],
            },
          }
        end
      end
    end

    private

    def row_from_data(data)
      {
        "id" => data["id"],
        "parent_id" => parent_id_of(data["id"]),
        "name" => data["name"],
      }
    end

    def parent_id_of(id)
      id.split("-")[0...-1].join("-").presence
    end
  end

  def gid
    self.class.gid(id)
  end

  def id_parts
    self.class.id_parts(id)
  end

  def name(locale: "en")
    self.class.find_localization(locale, id, "name") || super()
  end

  def full_name(locale: "en")
    ancestors.reverse.map { _1.name(locale:) }.push(name(locale:)).join(" > ")
  end

  # should never use translations
  def handleized_name
    "#{id}_#{self[:name].downcase.gsub(%r{[^a-z0-9\s\-_/\.\+#]}, "").gsub(/[\s\-\.]+/, "_")}"
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

  def ancestors_and_self
    [self] + ancestors
  end

  # depth-first given that matches how we want to use this
  def descendants
    children.flat_map { |child| [child] + child.descendants }
  end

  def descendants_and_self
    [self] + descendants
  end

  def next_child_id
    largest_child_id = children.map { _1.id.split("-").last.to_i }.max || 0

    "#{id}-#{largest_child_id + 1}"
  end

  def related_attribute_friendly_ids=(ids)
    self.related_attributes = Attribute.where(friendly_id: ids)
  end

  #
  # `data/` serialization

  def as_json_for_data
    {
      "id" => id,
      "name" => self[:name], # avoid localization
      "children" => children.sort_by(&:id_parts).map(&:id),
      "attributes" => AlphanumericSorter.sort(related_attributes.map(&:friendly_id), other_last: true),
    }
  end

  def as_json_for_data_with_descendants
    descendants_and_self.sort_by(&:id_parts).map(&:as_json_for_data)
  end

  #
  # `dist/` serialization

  def as_json_with_descendants(locale: "en")
    {
      "name" => name(locale:),
      "prefix" => id.downcase,
      "categories" => descendants_and_self.map { _1.as_json(locale:) },
    }
  end

  def as_json(locale: "en")
    {
      "id" => gid,
      "level" => level,
      "name" => name(locale:),
      "full_name" => full_name(locale:),
      "parent_id" => parent&.gid,
      "attributes" => related_attributes.map do
        {
          "id" => _1.gid,
          "name" => _1.name(locale:),
          "handle" => _1.handle,
          "description" => _1.description,
          "extended" => _1.extended?,
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

  def as_txt(padding: 0, locale:)
    "#{gid.ljust(padding)} : #{full_name(locale:)}"
  end

  private

  def id_matches_depth
    return if id.count("-") == level

    errors.add(:id, "#{id} must have #{level + 1} parts")
  end

  def id_starts_with_parent_id
    return if id.start_with?(parent.id)

    errors.add(:id, "#{id} must be prefixed by parent_id=#{parent_id}")
  end
end
