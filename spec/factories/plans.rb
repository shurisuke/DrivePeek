# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    association :user
    title { "テストドライブプラン" }

    # 本番と同様に start_point と goal_point を常に作成
    after(:create) do |plan|
      create(:start_point, plan: plan) unless plan.start_point
      create(:goal_point, plan: plan) unless plan.goal_point
    end

    trait :with_spots do
      transient do
        spots_count { 3 }
      end

      after(:create) do |plan, evaluator|
        evaluator.spots_count.times do |i|
          create(:plan_spot, plan: plan, position: i + 1)
        end
      end
    end

    trait :with_title do
      transient do
        plan_title { "カスタムタイトル" }
      end

      title { plan_title }
    end
  end
end
