# frozen_string_literal: true

FactoryBot.define do
  factory :goal_point do
    association :plan
    address { "東京都渋谷区渋谷1-1-1" }
    lat { 35.6580 }
    lng { 139.7016 }

    trait :different_location do
      address { "東京都新宿区新宿1-1-1" }
      lat { 35.6938 }
      lng { 139.7034 }
    end

    trait :in_ibaraki do
      address { "茨城県水戸市中央1-1-1" }
      lat { 36.3418 }
      lng { 140.4467 }
    end
  end
end
