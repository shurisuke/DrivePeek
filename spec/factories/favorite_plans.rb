# frozen_string_literal: true

FactoryBot.define do
  factory :favorite_plan do
    association :user
    association :plan
  end
end
