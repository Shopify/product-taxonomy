# frozen_string_literal: true

FactoryBot.define do
  factory :attribute do
    sequence(:name, 1) { "Attribute#{_1}" }
    handle { name.downcase }
    sequence(:friendly_id) { handle }
  end
end
