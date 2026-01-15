# ジャンルマスタデータ
# category: カテゴリ名, visible: UI表示するかどうか
GENRES = [
  # 食べる（親ジャンル）
  { name: "グルメ", slug: "gourmet", category: "食べる", visible: true },
  { name: "カフェ・スイーツ", slug: "cafe", category: "食べる", visible: true },
  { name: "バー", slug: "bar", category: "食べる", visible: true },

  # 食べる（細分化ジャンル - 非表示）
  # グルメ系
  { name: "ラーメン", slug: "ramen", category: "食べる", visible: false },
  { name: "寿司", slug: "sushi", category: "食べる", visible: false },
  { name: "焼肉", slug: "yakiniku", category: "食べる", visible: false },
  { name: "和食", slug: "washoku", category: "食べる", visible: false },
  { name: "中華料理", slug: "chinese", category: "食べる", visible: false },
  { name: "イタリアン", slug: "italian", category: "食べる", visible: false },
  { name: "カレー", slug: "curry", category: "食べる", visible: false },
  { name: "うどん・そば", slug: "udon_soba", category: "食べる", visible: false },
  { name: "ファストフード", slug: "fastfood", category: "食べる", visible: false },
  { name: "韓国料理", slug: "korean", category: "食べる", visible: false },
  { name: "タイ料理", slug: "thai", category: "食べる", visible: false },
  { name: "インド料理", slug: "indian", category: "食べる", visible: false },
  { name: "ベトナム料理", slug: "vietnamese", category: "食べる", visible: false },
  { name: "フレンチ", slug: "french", category: "食べる", visible: false },
  { name: "焼き鳥", slug: "yakitori", category: "食べる", visible: false },
  { name: "天ぷら", slug: "tempura", category: "食べる", visible: false },
  { name: "とんかつ", slug: "tonkatsu", category: "食べる", visible: false },
  { name: "餃子", slug: "gyoza", category: "食べる", visible: false },
  { name: "ステーキ", slug: "steak", category: "食べる", visible: false },
  { name: "海鮮", slug: "seafood", category: "食べる", visible: false },
  { name: "鍋", slug: "nabe", category: "食べる", visible: false },
  { name: "お好み焼き", slug: "okonomiyaki", category: "食べる", visible: false },
  { name: "ハンバーガー", slug: "hamburger", category: "食べる", visible: false },
  { name: "ピザ", slug: "pizza", category: "食べる", visible: false },
  { name: "牛丼", slug: "gyudon", category: "食べる", visible: false },
  { name: "定食", slug: "teishoku", category: "食べる", visible: false },
  # カフェ・スイーツ系
  { name: "喫茶店", slug: "kissaten", category: "食べる", visible: false },
  { name: "パンケーキ", slug: "pancake", category: "食べる", visible: false },
  { name: "ケーキ屋", slug: "cake_shop", category: "食べる", visible: false },
  { name: "パン屋", slug: "bakery", category: "食べる", visible: false },
  { name: "タピオカ", slug: "tapioca", category: "食べる", visible: false },
  { name: "ドーナツ", slug: "donut", category: "食べる", visible: false },
  { name: "アイスクリーム", slug: "icecream", category: "食べる", visible: false },
  { name: "クレープ", slug: "crepe", category: "食べる", visible: false },
  { name: "和菓子", slug: "wagashi", category: "食べる", visible: false },
  # バー系
  { name: "居酒屋", slug: "izakaya", category: "食べる", visible: false },
  { name: "スナック", slug: "snack_bar", category: "食べる", visible: false },
  { name: "パブ", slug: "pub", category: "食べる", visible: false },

  # 見る（親ジャンル）
  { name: "観光名所", slug: "sightseeing", category: "見る", visible: true },
  { name: "城・史跡", slug: "castle_historic", category: "見る", visible: true },
  { name: "神社仏閣", slug: "shrine_temple", category: "見る", visible: true },
  { name: "展望台・タワー", slug: "observatory_tower", category: "見る", visible: true },
  { name: "美術館", slug: "art_gallery", category: "見る", visible: false },
  { name: "博物館", slug: "museum", category: "見る", visible: false },
  { name: "映画館", slug: "movie_theater", category: "見る", visible: false },

  # 見る（細分化ジャンル - 非表示）
  { name: "古い町並み", slug: "old_townscape", category: "見る", visible: false },
  { name: "科学館", slug: "science_museum", category: "見る", visible: false },
  { name: "記念館・資料館", slug: "memorial_hall", category: "見る", visible: false },
  { name: "灯台", slug: "lighthouse", category: "見る", visible: false },
  { name: "橋", slug: "bridge", category: "見る", visible: false },
  { name: "ダム", slug: "dam", category: "見る", visible: false },
  { name: "工場見学", slug: "factory_tour", category: "見る", visible: false },
  { name: "夜景スポット", slug: "night_view", category: "見る", visible: false },
  { name: "パワースポット", slug: "power_spot", category: "見る", visible: false },
  { name: "世界遺産", slug: "world_heritage", category: "見る", visible: false },
  { name: "ロープウェイ・ケーブルカー", slug: "ropeway", category: "見る", visible: false },
  { name: "市場・朝市", slug: "market", category: "見る", visible: false },
  { name: "商店街", slug: "shopping_street", category: "見る", visible: false },

  # お風呂
  { name: "温泉・スパ", slug: "onsen", category: "お風呂", visible: true },
  { name: "サウナ", slug: "sauna", category: "お風呂", visible: true },

  # 動物
  { name: "動物園", slug: "zoo", category: "動物", visible: true },
  { name: "水族館", slug: "aquarium", category: "動物", visible: true },

  # 自然（親ジャンル）
  { name: "海・海岸", slug: "sea_coast", category: "自然", visible: true },
  { name: "山・高原", slug: "mountain", category: "自然", visible: true },
  { name: "絶景・展望", slug: "scenic_view", category: "自然", visible: true },
  { name: "公園", slug: "park", category: "自然", visible: true },
  { name: "花・庭園", slug: "garden_flower", category: "自然", visible: true },
  { name: "湖・滝", slug: "lake_waterfall", category: "自然", visible: true },

  # 自然（細分化ジャンル - 非表示）
  { name: "牧場", slug: "ranch", category: "自然", visible: false },
  { name: "洞窟・鍾乳洞", slug: "cave", category: "自然", visible: false },

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
  { name: "宿泊施設", slug: "accommodation", category: "泊まる", visible: true },

  # その他
  { name: "施設", slug: "facility", category: "その他", visible: false }
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
