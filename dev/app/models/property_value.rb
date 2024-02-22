class PropertyValue < ApplicationRecord
  default_scope { order(Arel.sql("CASE WHEN name = 'Other' THEN 1 ELSE 0 END, name")) }

  has_and_belongs_to_many :properties

  validates :name, presence: true

  def gid
    "gid://shopify/Taxonomy/Attribute/#{id.gsub(/-/, '/')}"
  end
end
