# frozen_string_literal: true

class Integration < ApplicationRecord
  has_many :mapping_rules
  validates :name, presence: true

  serialize :available_versions, type: Array, coder: JSON

  class << self
    #
    # `data/` deserialization

    def new_from_data(data)
      new(row_from_data(data))
    end

    def insert_all_from_data(data, ...)
      insert_all!(Array(data).map { row_from_data(_1) }, ...)
    end

    private

    def row_from_data(data)
      {
        "name" => data["name"],
        "available_versions" => data["available_versions"],
      }
    end
  end

  def as_json
    {
      "name" => name,
      "available_versions" => available_versions,
    }
  end

  def as_txt(padding:)
    "#{gid.ljust(padding)} : #{name}"
  end

  def gid
    "gid://shopify/Integration/#{id}"
  end
end
