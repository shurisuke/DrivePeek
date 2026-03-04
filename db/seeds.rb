# ジャンルマスタデータ
# category: カテゴリ名, visible: UI表示するかどうか, parent_slug: 親ジャンル, emoji: マーカー表示用絵文字
GENRES = [
  # ==========================================
  # 食べる
  # ==========================================
  { name: "ごはん", slug: "food", category: "食べる", visible: true, emoji: "🍴" },
  { name: "カフェ・スイーツ", slug: "sweets_cafe", category: "食べる", visible: true, emoji: "☕" },

  # ==========================================
  # 見る
  # ==========================================
  { name: "観光名所", slug: "sightseeing", category: "見る", visible: true, emoji: "🏛️" },
  { name: "ミュージアム", slug: "museum_category", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏛️" },
  { name: "神社仏閣", slug: "shrine_temple", category: "見る", visible: true, emoji: "⛩️" },
  { name: "映画館", slug: "movie_theater", category: "見る", visible: false },
  { name: "文化財", slug: "cultural_property", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏛️" },
  { name: "夜景スポット", slug: "night_view", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🌃" },
  { name: "城", slug: "castle", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏯" },
  { name: "史跡", slug: "historic_site", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏛️" },
  { name: "絶景", slug: "scenic_view", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🌅" },
  { name: "ダム", slug: "dam", category: "その他", visible: false, emoji: "💧" },

  # ==========================================
  # 買う
  # ==========================================
  { name: "道の駅", slug: "roadside_station", category: "買う", visible: true, emoji: "🚗" },
  { name: "SA/PA", slug: "service_area", category: "買う", visible: true, emoji: "🚗" },
  # ショッピング（親ジャンル・子ジャンルは非表示）
  { name: "ショッピング", slug: "shopping", category: "買う", visible: true, emoji: "🛍️" },
  { name: "雑貨屋", slug: "variety_store", category: "買う", visible: false, parent_slug: "shopping", emoji: "🛍️" },
  { name: "お土産屋", slug: "souvenir_shop", category: "買う", visible: false, parent_slug: "shopping", emoji: "🛍️" },
  { name: "デパート", slug: "department_store", category: "買う", visible: false, parent_slug: "shopping", emoji: "🏬" },
  { name: "アウトレット", slug: "outlet", category: "買う", visible: false, parent_slug: "shopping", emoji: "👗" },
  { name: "直売所", slug: "farm_stand", category: "買う", visible: false, parent_slug: "shopping", emoji: "🥬" },
  { name: "酒屋", slug: "liquor_store", category: "買う", visible: false, parent_slug: "shopping", emoji: "🍾" },
  { name: "市場・朝市", slug: "market", category: "買う", visible: false, parent_slug: "shopping", emoji: "🛒" },

  # ==========================================
  # 動物
  # ==========================================
  { name: "動物園", slug: "zoo", category: "動物", visible: true, emoji: "🦁" },
  { name: "水族館", slug: "aquarium", category: "動物", visible: true, emoji: "🐬" },

  # ==========================================
  # 自然
  # ==========================================
  { name: "海スポット", slug: "sea_coast", category: "自然", visible: true, emoji: "🏖️" },
  { name: "山スポット", slug: "mountain", category: "自然", visible: true, emoji: "⛰️" },
  { name: "湖・滝スポット", slug: "lake_waterfall", category: "自然", visible: true, emoji: "💧" },
  { name: "洞窟", slug: "cave", category: "自然", visible: true, emoji: "🕳️" },
  { name: "公園", slug: "park", category: "自然", visible: true, emoji: "🌳" },

  # ==========================================
  # 遊ぶ
  # ==========================================
  { name: "テーマパーク", slug: "theme_park", category: "遊ぶ", visible: true, emoji: "🎢" },
  { name: "アクティビティ施設", slug: "activity", category: "遊ぶ", visible: true, emoji: "🪂" },
  { name: "プール", slug: "water_park", category: "遊ぶ", visible: true, emoji: "💧" },
  { name: "釣り堀", slug: "fishing_pond", category: "遊ぶ", visible: true, emoji: "🎣" },

  # ==========================================
  # 泊まる
  # ==========================================
  { name: "宿泊施設", slug: "accommodation", category: "泊まる", visible: true, emoji: "🏨" },

  # ==========================================
  # 温まる
  # ==========================================
  { name: "温泉", slug: "bath", category: "温まる", visible: true, emoji: "♨️" },

  # ==========================================
  # その他（非表示・AI判定用）
  # ==========================================
  { name: "バー", slug: "bar", category: "その他", visible: false, emoji: "🍷" },
  { name: "コンビニ", slug: "convenience_store", category: "その他", visible: false, emoji: "🏪" },
  { name: "スーパー", slug: "supermarket", category: "その他", visible: false, emoji: "🛒" },
  { name: "洋服屋", slug: "clothing_store", category: "その他", visible: false, emoji: "👚" },
  { name: "花屋", slug: "flower_shop", category: "その他", visible: false, emoji: "💐" },
  { name: "施設", slug: "facility", category: "その他", visible: false },
  { name: "駅", slug: "station", category: "その他", visible: false, emoji: "🚉" },
  { name: "空港", slug: "airport", category: "その他", visible: false, emoji: "✈️" },
  { name: "港", slug: "port", category: "その他", visible: false, emoji: "⚓" },
  { name: "駐車場", slug: "parking", category: "その他", visible: false, emoji: "🅿️" },
  { name: "ガソリンスタンド", slug: "gas_station", category: "その他", visible: false, emoji: "⛽" },
  { name: "病院", slug: "hospital", category: "その他", visible: false, emoji: "🏥" },
  { name: "学校", slug: "school", category: "その他", visible: false, emoji: "🏫" },
  { name: "役所", slug: "government_office", category: "その他", visible: false, emoji: "🏢" },
  { name: "警察署", slug: "police", category: "その他", visible: false, emoji: "👮" },
  { name: "消防署", slug: "fire_station", category: "その他", visible: false, emoji: "🚒" },
  { name: "郵便局", slug: "post_office", category: "その他", visible: false, emoji: "📮" },
  { name: "図書館", slug: "library", category: "その他", visible: false, emoji: "📚" },
  { name: "銀行", slug: "bank", category: "その他", visible: false, emoji: "🏦" },
  { name: "工場", slug: "factory", category: "その他", visible: false, emoji: "🏭" },
  { name: "ホームセンター", slug: "home_center", category: "その他", visible: false, emoji: "🔧" },
  { name: "ペットショップ", slug: "pet_shop", category: "その他", visible: false, emoji: "🐾" },
  { name: "カーショップ", slug: "car_shop", category: "その他", visible: false, emoji: "🚗" },
  { name: "事業所", slug: "office", category: "その他", visible: false, emoji: "🏢" },
  { name: "家具屋", slug: "furniture_store", category: "その他", visible: false, emoji: "🪑" },
  { name: "カラオケ", slug: "karaoke", category: "その他", visible: false, emoji: "🎤" },
  { name: "ゲームセンター", slug: "game_center", category: "その他", visible: false, emoji: "🎮" },
  { name: "スポーツショップ", slug: "sports_shop", category: "その他", visible: false, emoji: "✨" },
  { name: "キャンプ場", slug: "campsite", category: "その他", visible: false, emoji: "⛺" },
  { name: "BBQ場", slug: "bbq_site", category: "その他", visible: false, emoji: "🍖" },
  { name: "漫画喫茶", slug: "manga_cafe", category: "その他", visible: false, emoji: "📚" },
  { name: "ジム", slug: "gym", category: "その他", visible: false, emoji: "💪" },
  { name: "ワイナリー", slug: "winery", category: "その他", visible: false, emoji: "🍷" },
  { name: "本屋", slug: "bookstore", category: "その他", visible: false, emoji: "📚" },
  { name: "農園", slug: "farm", category: "その他", visible: false, emoji: "🌾" },
  { name: "牧場", slug: "ranch", category: "その他", visible: false, emoji: "🐄" },
  { name: "ロープウェイ・ケーブルカー", slug: "ropeway", category: "その他", visible: false, emoji: "🚡" },
  { name: "運動場", slug: "sports_ground", category: "その他", visible: false, emoji: "⚽" },
  { name: "ゴルフ場", slug: "golf_course", category: "その他", visible: false, emoji: "⛳" },
  { name: "スキー場", slug: "ski_resort", category: "その他", visible: false, emoji: "⛷️" },
  { name: "スケート場", slug: "skating_rink", category: "その他", visible: false, emoji: "⛸️" },
  { name: "フットサル場", slug: "futsal_court", category: "その他", visible: false, emoji: "⚽" },
  { name: "ボウリング場", slug: "bowling", category: "その他", visible: false, emoji: "🎳" }
].freeze

# 全ジャンルを作成・更新（parent_id なし）
GENRES.each.with_index(1) do |attrs, position|
  genre = Genre.find_or_initialize_by(slug: attrs[:slug])
  genre.assign_attributes(
    name: attrs[:name],
    category: attrs[:category],
    visible: attrs[:visible],
    emoji: attrs[:emoji] || "✨",
    position: position,
    parent_id: nil # 一旦リセット
  )
  genre.save!
end

# parent_slug から parent_id を設定
GENRES.each do |attrs|
  next unless attrs[:parent_slug]

  genre = Genre.find_by(slug: attrs[:slug])
  parent = Genre.find_by(slug: attrs[:parent_slug])

  if genre && parent
    genre.update!(parent_id: parent.id)
  end
end

puts "Created/Updated #{Genre.count} genres"
