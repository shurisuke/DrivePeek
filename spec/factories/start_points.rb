# frozen_string_literal: true

FactoryBot.define do
  factory :start_point do
    association :plan
    address { "東京都渋谷区渋谷1-1-1" }
    lat { 35.6580 }
    lng { 139.7016 }
    prefecture { "東京都" }
    city { "渋谷区" }
    departure_time { Time.zone.parse("09:00") }
    toll_used { false }
    move_time { 30 }
    move_distance { 10.5 }

    trait :with_toll do
      toll_used { true }
    end

    trait :no_departure_time do
      departure_time { nil }
    end

    trait :in_ibaraki do
      address { "茨城県水戸市中央1-1-1" }
      lat { 36.3418 }
      lng { 140.4467 }
      prefecture { "茨城県" }
      city { "水戸市" }
    end
  end
end
