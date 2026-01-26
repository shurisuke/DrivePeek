# frozen_string_literal: true

FactoryBot.define do
  factory :spot_comment do
    association :user
    association :spot
    body { "テストコメントです。10文字以上必要です。" }

    trait :short do
      body { "短いコメント" }
    end

    trait :long do
      body { "これは長いコメントです。" * 5 }
    end
  end
end
