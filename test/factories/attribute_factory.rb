# frozen_string_literal: true

FactoryBot.define do
  factory :attribute do
    sequence(:name) { "Attribute" }
    handle { name.downcase }
    friendly_id { handle }
  end
end
