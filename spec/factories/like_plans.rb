# frozen_string_literal: true

FactoryBot.define do
  factory :like_plan do
    association :user
    association :plan
  end
end
