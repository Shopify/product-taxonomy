# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :mapping_rules
  serialize :payload, coder: JSON

  def as_json(options = {})
    super(options.merge({ methods: :type }))
  end
end
