# frozen_string_literal: true

FactoryBot.define do
  factory :identity do
    association :user
    provider { "twitter2" }
    sequence(:uid) { |n| "uid_#{n}_#{SecureRandom.hex(8)}" }

    trait :line do
      provider { "line" }
    end

    trait :twitter do
      provider { "twitter2" }
    end
  end
end
