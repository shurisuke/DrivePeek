# Google Places API の types から Genre を判定するマッパー
#
# 使い方:
#   genre_ids = GenreMapper.map(["restaurant", "food", "point_of_interest"])
#   # => [1] (グルメのID)
#
class GenreMapper
  # Google types → Genre slug のマッピング定義
  # 優先度順（先にマッチしたものを採用）
  MAPPING = {
    # グルメ
    "restaurant" => "gourmet",
    "food" => "gourmet",
    "meal_delivery" => "gourmet",
    "meal_takeaway" => "gourmet",
    "bakery" => "gourmet",

    # カフェ・スイーツ
    "cafe" => "cafe",

    # 酒屋
    "liquor_store" => "liquor_store",

    # バー
    "bar" => "bar",
    "night_club" => "bar",

    # 公園
    "park" => "park",
    "national_park" => "park",

    # 海・海岸
    "beach" => "sea_coast",

    # 山・高原
    "hiking_area" => "mountain",

    # 花・庭園
    "garden" => "garden_flower",

    # 城・史跡
    "historical_place" => "castle_historic",
    "monument" => "castle_historic",

    # 博物館
    "museum" => "museum",

    # 美術館
    "art_gallery" => "art_gallery",

    # テーマパーク
    "amusement_park" => "theme_park",

    # 動物園
    "zoo" => "zoo",

    # 水族館
    "aquarium" => "aquarium",

    # 温泉・スパ
    "spa" => "onsen",

    # 宿泊施設
    "lodging" => "accommodation",
    "hotel" => "accommodation",
    "motel" => "accommodation",
    "rv_park" => "accommodation",
    "campground" => "accommodation",

    # ショッピング
    "shopping_mall" => "shopping",
    "department_store" => "shopping",
    "store" => "shopping",
    "supermarket" => "shopping",
    "convenience_store" => "shopping",

    # 神社仏閣
    "place_of_worship" => "shrine_temple",
    "church" => "shrine_temple",
    "hindu_temple" => "shrine_temple",
    "mosque" => "shrine_temple",
    "synagogue" => "shrine_temple",

    # ジム
    "gym" => "gym",

    # ボウリング場
    "bowling_alley" => "bowling",

    # ゴルフ場
    "golf_course" => "golf_course",

    # スキー場
    "ski_resort" => "ski_resort",

    # プール
    "water_park" => "water_park",
    "swimming_pool" => "water_park",

    # 映画館
    "movie_theater" => "movie_theater",

    # 交通系
    "transit_station" => "station",
    "train_station" => "station",
    "subway_station" => "station",
    "airport" => "airport",
    "seaport" => "port",
    "parking" => "parking",
    "gas_station" => "gas_station",

    # 公共施設
    "hospital" => "hospital",
    "school" => "school",
    "university" => "school",
    "local_government_office" => "government_office",
    "city_hall" => "government_office",
    "police" => "police",
    "fire_station" => "fire_station",
    "post_office" => "post_office",
    "library" => "library",

    # 金融
    "bank" => "bank",

    # 観光名所（汎用的なので最後に判定）
    "tourist_attraction" => "sightseeing"
  }.freeze

  # マッピング不可能な場合に AI フォールバックが必要な Genre slugs
  AI_REQUIRED_GENRES = %w[
    lake_waterfall
    scenic_view
    roadside_station
    activity
    sauna
  ].freeze

  # 他のジャンルがマッチした場合に除外する汎用ジャンル
  # グルメも汎用的なので、AIでより具体的なジャンルを判定させる
  FALLBACK_GENRES = %w[sightseeing gourmet].freeze

  class << self
    # Google types 配列から Genre IDs を返す（最大2個）
    # マッピングできない場合は空配列を返す
    #
    # @param types [Array<String>] Google Places API の types
    # @return [Array<Integer>] マッチした Genre の ID 配列（最大2個）
    def map(types)
      return [] if types.blank?

      slugs = types.filter_map { |type| MAPPING[type] }.uniq
      return [] if slugs.empty?

      # 具体的なジャンルがある場合は汎用ジャンル（観光名所など）を除外
      slugs = exclude_fallback_genres(slugs)

      # 最大2個に制限
      Genre.where(slug: slugs).pluck(:id).take(2)
    end

    # マッピングが成功したかどうか
    #
    # @param types [Array<String>] Google Places API の types
    # @return [Boolean]
    def mappable?(types)
      map(types).present?
    end

    private

    def exclude_fallback_genres(slugs)
      specific_slugs = slugs - FALLBACK_GENRES
      specific_slugs.present? ? specific_slugs : slugs
    end
  end
end
