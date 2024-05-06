# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    sequence(:id, 1) do
      if parent.nil?
        "aa"
      else
        "#{parent.id}-#{_1}"
      end
    end
    name { "Category #{id}" }
  end
end
