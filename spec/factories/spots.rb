# frozen_string_literal: true

FactoryBot.define do
  factory :spot do
    sequence(:name) { |n| "テストスポット#{n}" }
    sequence(:place_id) { |n| "ChIJ#{SecureRandom.alphanumeric(20)}_#{n}" }
    address { "東京都渋谷区渋谷1-1-1" }
    lat { 35.6580 + rand(-0.1..0.1) }
    lng { 139.7016 + rand(-0.1..0.1) }
    prefecture { "東京都" }
    city { "渋谷区" }

    trait :in_tokyo do
      prefecture { "東京都" }
      city { "渋谷区" }
      lat { 35.6580 }
      lng { 139.7016 }
    end

    trait :in_ibaraki do
      prefecture { "茨城県" }
      city { "ひたちなか市" }
      address { "茨城県ひたちなか市磯崎町8252-3" }
      lat { 36.3964 }
      lng { 140.5347 }
    end

    trait :in_oarai do
      prefecture { "茨城県" }
      city { "東茨城郡大洗町" }
      address { "茨城県東茨城郡大洗町磯浜町8252-3" }
      lat { 36.3133 }
      lng { 140.5764 }
    end

    trait :with_genres do
      transient do
        genre_count { 2 }
        genre_slugs { [] }
      end

      after(:create) do |spot, evaluator|
        if evaluator.genre_slugs.any?
          genres = Genre.where(slug: evaluator.genre_slugs)
          genres.each { |g| spot.genres << g unless spot.genres.include?(g) }
        else
          evaluator.genre_count.times do
            genre = create(:genre)
            spot.genres << genre unless spot.genres.include?(genre)
          end
        end
      end
    end
  end
end
