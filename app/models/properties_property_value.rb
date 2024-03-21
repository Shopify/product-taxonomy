# frozen_string_literal: true

class PropertiesPropertyValue < ApplicationRecord
  belongs_to :property
  belongs_to :property_value
end
