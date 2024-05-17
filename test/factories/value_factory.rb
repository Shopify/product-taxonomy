# frozen_string_literal: true

FactoryBot.define do
  factory :value do
    sequence(:name) { "Value" }
    handle { name.downcase }
    friendly_id { [primary_attribute&.handle, handle].compact.join("__") }
  end
end
