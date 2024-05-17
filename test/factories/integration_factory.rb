# frozen_string_literal: true

FactoryBot.define do
  factory :integration do
    sequence(:id, 1)
    name { "Integration #{id}" }
  end
end
