# frozen_string_literal: true

FactoryBot.define do
  factory :integration do
    sequence(:name, 1) { "Integration#{_1}" }
  end
end
