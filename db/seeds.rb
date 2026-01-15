# ジャンルマスタデータ
# category: カテゴリ名, visible: UI表示するかどうか
GENRES = [
  # 食べる
  { name: "グルメ", slug: "gourmet", category: "食べる", visible: true },
  { name: "カフェ・スイーツ", slug: "cafe", category: "食べる", visible: true },
  { name: "バー", slug: "bar", category: "食べる", visible: true },

  # 見る
  { name: "観光名所", slug: "sightseeing", category: "見る", visible: true },
  { name: "城・史跡", slug: "castle_historic", category: "見る", visible: true },
  { name: "神社仏閣", slug: "shrine_temple", category: "見る", visible: true },
  { name: "美術館", slug: "art_gallery", category: "見る", visible: false },
  { name: "博物館", slug: "museum", category: "見る", visible: false },
  { name: "映画館", slug: "movie_theater", category: "見る", visible: false },

  # お風呂
  { name: "温泉・スパ", slug: "onsen", category: "お風呂", visible: true },
  { name: "サウナ", slug: "sauna", category: "お風呂", visible: true },

  # 動物
  { name: "動物園", slug: "zoo", category: "動物", visible: true },
  { name: "水族館", slug: "aquarium", category: "動物", visible: true },

  # 自然
  { name: "海・海岸", slug: "sea_coast", category: "自然", visible: true },
  { name: "山・高原", slug: "mountain", category: "自然", visible: true },
  { name: "絶景・展望", slug: "scenic_view", category: "自然", visible: true },
  { name: "公園", slug: "park", category: "自然", visible: true },
  { name: "花・庭園", slug: "garden_flower", category: "自然", visible: true },
  { name: "湖・滝", slug: "lake_waterfall", category: "自然", visible: true },

  # 遊ぶ
  { name: "テーマパーク", slug: "theme_park", category: "遊ぶ", visible: true },
  { name: "アクティビティ施設", slug: "activity", category: "遊ぶ", visible: true },
  { name: "スキー場", slug: "ski_resort", category: "遊ぶ", visible: true },
  { name: "プール", slug: "water_park", category: "遊ぶ", visible: true },
  { name: "ジム", slug: "gym", category: "遊ぶ", visible: false },
  { name: "ボウリング場", slug: "bowling", category: "遊ぶ", visible: false },
  { name: "ゴルフ場", slug: "golf_course", category: "遊ぶ", visible: true },

  # 買う
  { name: "ショッピング", slug: "shopping", category: "買う", visible: true },
  { name: "道の駅・SA/PA", slug: "roadside_station", category: "買う", visible: true },
  { name: "ワイナリー", slug: "winery", category: "買う", visible: true },
  { name: "酒屋", slug: "liquor_store", category: "買う", visible: true },

  # 泊まる
  { name: "宿泊施設", slug: "accommodation", category: "泊まる", visible: true }
].freeze

GENRES.each.with_index(1) do |attrs, position|
  genre = Genre.find_or_initialize_by(slug: attrs[:slug])
  genre.assign_attributes(
    name: attrs[:name],
    category: attrs[:category],
    visible: attrs[:visible],
    position: position
  )
  genre.save!
end

puts "Created #{Genre.count} genres"
