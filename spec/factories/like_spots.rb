# frozen_string_literal: true

FactoryBot.define do
  factory :like_spot do
    association :user
    association :spot
  end
end
