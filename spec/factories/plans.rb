# frozen_string_literal: true

FactoryBot.define do
  factory :plan do
    association :user
    title { "テストドライブプラン" }

    trait :with_start_point do
      after(:create) do |plan|
        create(:start_point, plan: plan)
      end
    end

    trait :with_goal_point do
      after(:create) do |plan|
        create(:goal_point, plan: plan)
      end
    end

    trait :with_spots do
      transient do
        spots_count { 3 }
      end

      after(:create) do |plan, evaluator|
        create(:start_point, plan: plan) unless plan.start_point
        create(:goal_point, plan: plan) unless plan.goal_point
        evaluator.spots_count.times do |i|
          create(:plan_spot, plan: plan, position: i + 1)
        end
      end
    end

    trait :complete do
      with_start_point
      with_goal_point
      with_spots
    end

    trait :with_title do
      transient do
        plan_title { "カスタムタイトル" }
      end

      title { plan_title }
    end
  end
end
