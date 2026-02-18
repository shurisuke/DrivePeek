# frozen_string_literal: true

FactoryBot.define do
  factory :genre do
    sequence(:name) { |n| "ジャンル#{n}" }
    sequence(:slug) { |n| "genre_#{n}" }
    sequence(:position) { |n| n }
    visible { true }

    trait :food do
      name { "ごはん" }
      slug { "food" }
    end

    trait :bath do
      name { "温泉" }
      slug { "bath" }
    end

    trait :sightseeing do
      name { "観光名所" }
      slug { "sightseeing" }
    end

    trait :nature do
      name { "自然・景観" }
      slug { "nature" }
    end

    trait :facility do
      name { "施設" }
      slug { "facility" }
      visible { false }
    end

    trait :with_children do
      transient do
        children_count { 2 }
      end

      after(:create) do |genre, evaluator|
        create_list(:genre, evaluator.children_count, parent: genre)
      end
    end
  end
end
