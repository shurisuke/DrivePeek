# frozen_string_literal: true

FactoryBot.define do
  factory :plan_spot do
    association :plan
    association :spot
    sequence(:position) { |n| n }
    move_time { 30 }
    move_distance { 10.5 }
    move_cost { 0 }
    toll_used { false }
    stay_duration { 60 }
    arrival_time { Time.zone.parse("09:30") }
    departure_time { Time.zone.parse("10:30") }

    trait :with_toll do
      toll_used { true }
      move_cost { 500 }
    end

    trait :with_memo do
      memo { "テストメモです" }
    end

    trait :short_stay do
      stay_duration { 30 }
    end

    trait :long_stay do
      stay_duration { 120 }
    end
  end
end
