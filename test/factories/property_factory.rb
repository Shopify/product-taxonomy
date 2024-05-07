# frozen_string_literal: true

FactoryBot.define do
  factory :property do
    sequence(:id, 1)
    name { "Property#{id}" }
    handle { name.downcase }
    friendly_id { handle }
  end
end
