# frozen_string_literal: true

FactoryBot.define do
  factory :mapping_rule do
    association :integration, factory: :integration
    association :input, factory: :product
    association :output, factory: :product # TODO: FactoryBot is upset about this

    sequence(:input_id, 1)
    sequence(:output_id, 1)
    input_type { "Product" }
    output_type { "GoogleProduct" }
    input_version { "shopify/v1" }
    output_version { "google/v1" }
  end
end
