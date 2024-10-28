# frozen_string_literal: true

FactoryBot.define do
  factory :value do
    association :primary_attribute, factory: :attribute

    sequence(:name, 1) { "Value#{_1}" }
    handle { "#{primary_attribute.handle}-#{name.downcase}" }
    sequence(:friendly_id) { "#{primary_attribute.handle}__#{name.downcase}" }
  end
end
