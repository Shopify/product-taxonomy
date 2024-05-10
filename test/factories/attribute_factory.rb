# frozen_string_literal: true

FactoryBot.define do
  factory :attribute do
    sequence(:id, 1)
    name { "Attribute#{id}" }
    handle { name.downcase }
    friendly_id { handle }
  end
end
