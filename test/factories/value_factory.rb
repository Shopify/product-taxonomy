# frozen_string_literal: true

FactoryBot.define do
  factory :value do
    sequence(:id, 1)
    name { "Value#{id}" }
    handle { name.downcase }
    friendly_id { [primary_attribute&.handle, handle].compact.join("__") }
  end
end
