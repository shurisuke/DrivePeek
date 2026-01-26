# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    status { :active }
    confirmed_at { Time.current }

    # メール確認済み状態で作成（コールバック前に設定済み）
    after(:build) { |user| user.skip_confirmation_notification! }

    trait :hidden do
      status { :hidden }
    end

    trait :with_profile do
      residence { "東京都" }
      age_group { :thirties }
      gender { :male }
    end

    trait :sns_only do
      email { nil }
      registering_via_sns { true }
      after(:build) do |user|
        user.identities.build(provider: "twitter2", uid: SecureRandom.uuid)
      end
    end

    trait :with_line do
      after(:create) do |user|
        create(:identity, user: user, provider: "line")
      end
    end

    trait :with_twitter do
      after(:create) do |user|
        create(:identity, user: user, provider: "twitter2")
      end
    end
  end
end
