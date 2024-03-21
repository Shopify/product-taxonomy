# frozen_string_literal: true

class Category < ApplicationRecord
  default_scope { order(:name) }

  scope :verticals, -> { where(parent_id: nil) }

  has_many :children, class_name: "Category", inverse_of: :parent
  belongs_to :parent, class_name: "Category", optional: true

  has_and_belongs_to_many :properties,
    join_table: :categories_properties,
    foreign_key: :category_id,
    association_foreign_key: :property_friendly_id
  def property_friendly_ids=(ids)
    self.properties = Property.where(friendly_id: ids)
  end

  validates :id,
    presence: { strict: true },
    format: { with: /\A[a-z]{2}(-\d+)*\z/ }
  validates :name,
    presence: { strict: true }
  validate :id_matches_depth
  validate :id_starts_with_parent_id,
    unless: :root?
  validates_associated :children

  def gid
    "gid://shopify/Taxonomy/Category/#{id}"
  end

  def full_name
    ancestors.reverse.map(&:name).push(name).join(" > ")
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
