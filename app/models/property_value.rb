# frozen_string_literal: true

class PropertyValue < ApplicationRecord
  default_scope { order(Arel.sql("CASE WHEN name = 'Other' THEN 1 ELSE 0 END, name")) }

  has_and_belongs_to_many :properties,
    join_table: :properties_property_values

  validates :name, presence: true

  def gid
    "gid://shopify/Taxonomy/Value/#{id}"
  end
end
