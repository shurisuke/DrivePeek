# frozen_string_literal: true

module MapHelper
  # InfoWindowのズームスケール（4段階）
  INFOWINDOW_ZOOM_SCALES = %w[sm md lg xl].freeze
  INFOWINDOW_DEFAULT_ZOOM_INDEX = 1  # md

  # Google Place types → 日本語ラベル
  PLACE_TYPE_LABELS = {
    "restaurant" => "レストラン",
    "cafe" => "カフェ",
    "bar" => "バー",
    "bakery" => "ベーカリー",
    "meal_takeaway" => "テイクアウト",
    "tourist_attraction" => "観光スポット",
    "museum" => "博物館",
    "art_gallery" => "美術館",
    "park" => "公園",
    "zoo" => "動物園",
    "aquarium" => "水族館",
    "amusement_park" => "遊園地",
    "campground" => "キャンプ場",
    "rv_park" => "RVパーク",
    "lodging" => "宿泊施設",
    "hotel" => "ホテル",
    "shopping_mall" => "ショッピングモール",
    "store" => "ショップ",
    "convenience_store" => "コンビニ",
    "supermarket" => "スーパー",
    "gas_station" => "ガソリンスタンド",
    "parking" => "駐車場",
    "car_wash" => "洗車場",
    "spa" => "スパ",
    "gym" => "ジム",
    "stadium" => "スタジアム",
    "movie_theater" => "映画館",
    "night_club" => "ナイトクラブ",
    "bowling_alley" => "ボウリング",
    "temple" => "寺院",
    "shrine" => "神社",
    "church" => "教会",
    "cemetery" => "墓地",
    "hospital" => "病院",
    "pharmacy" => "薬局",
    "school" => "学校",
    "university" => "大学",
    "library" => "図書館",
    "city_hall" => "市役所",
    "post_office" => "郵便局",
    "police" => "警察",
    "fire_station" => "消防署",
    "train_station" => "駅",
    "bus_station" => "バス停",
    "airport" => "空港",
    "subway_station" => "地下鉄駅",
    "natural_feature" => "自然",
    "point_of_interest" => "スポット"
  }.freeze

  # typesから日本語ラベルを取得（最大2件）
  def place_type_labels(types, max: 2)
    return [] if types.blank?

    labels = []
    types.each do |type|
      label = PLACE_TYPE_LABELS[type.to_s]
      if label
        labels << label
        break if labels.size >= max
      end
    end
    labels.presence || [ "スポット" ]
  end

  # InfoWindowのデフォルトズームスケールを返す
  def infowindow_default_zoom_scale
    INFOWINDOW_ZOOM_SCALES[INFOWINDOW_DEFAULT_ZOOM_INDEX]
  end

  # InfoWindowのズームスケール配列をJSON形式で返す
  def infowindow_zoom_scales_json
    INFOWINDOW_ZOOM_SCALES.to_json
  end
end
