class Category < ApplicationRecord
  default_scope { order(:name) }

  scope :verticals, -> { where(parent_id: nil) }

  has_many :children, class_name: 'Category', inverse_of: :parent
  belongs_to :parent, class_name: 'Category', optional: true
  has_and_belongs_to_many :properties

  validates :id,
    presence: { strict: true },
    format: { with: /\A[a-z]{2}(\-[0-9]+)*\z/ }
  validates :name,
    presence: { strict: true }
  validate :assigned_to_correct_parent

  def assigned_to_correct_parent
    return if parent.nil?

    expected_parts = id.split("-").tap(&:pop)
    parent_parts = parent.id.split("-")
    return if expected_parts == parent_parts

    errors.add(:parent_id, "must be a prefix of id")
  end

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
end
