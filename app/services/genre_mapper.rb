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

    # アクティビティ
    "gym" => "activity",
    "stadium" => "activity",
    "bowling_alley" => "activity",

    # 観光名所（汎用的なので最後に判定）
    "tourist_attraction" => "sightseeing"
  }.freeze

  # マッピング不可能な場合に AI フォールバックが必要な Genre slugs
  AI_REQUIRED_GENRES = %w[
    sea_coast
    mountain
    lake_waterfall
    garden_flower
    scenic_view
    castle_historic
    roadside_station
  ].freeze

  # 他のジャンルがマッチした場合に除外する汎用ジャンル
  FALLBACK_GENRES = %w[sightseeing].freeze

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
