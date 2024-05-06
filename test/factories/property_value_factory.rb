# frozen_string_literal: true

FactoryBot.define do
  factory :property_value do
    sequence(:id, 1)
    name { "Value#{id}" }
    handle { name.downcase }
    friendly_id { [primary_property&.handle, handle].compact.join("__") }
  end
end
