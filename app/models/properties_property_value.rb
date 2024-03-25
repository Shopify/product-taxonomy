# frozen_string_literal: true

class PropertiesPropertyValue < ApplicationRecord
  belongs_to :property
  belongs_to :property_value, foreign_key: :property_value_friendly_id, primary_key: :friendly_id
end
