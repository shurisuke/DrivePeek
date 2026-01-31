# ジャンルマスタデータ
# category: カテゴリ名, visible: UI表示するかどうか, parent_slug: 親ジャンル
GENRES = [
  # 食べる（親ジャンル）
  { name: "グルメ", slug: "gourmet", category: "食べる", visible: true },
  { name: "カフェ・スイーツ", slug: "cafe", category: "食べる", visible: true },
  { name: "バー", slug: "bar", category: "食べる", visible: false },

  # 食べる（細分化ジャンル - 表示）
  # グルメ系 - 人気の定番
  { name: "ラーメン", slug: "ramen", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "寿司", slug: "sushi", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "焼肉", slug: "yakiniku", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "カレー", slug: "curry", category: "食べる", visible: true, parent_slug: "gourmet" },
  # グルメ系 - 和食
  { name: "和食", slug: "washoku", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "うどん・そば", slug: "udon_soba", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "天ぷら", slug: "tempura", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "とんかつ", slug: "tonkatsu", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "焼き鳥", slug: "yakitori", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "海鮮", slug: "seafood", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "お好み焼き", slug: "okonomiyaki", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "たこ焼き", slug: "takoyaki", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "牛丼", slug: "gyudon", category: "食べる", visible: true, parent_slug: "gourmet" },
  # グルメ系 - 洋食
  { name: "イタリアン", slug: "italian", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "フレンチ", slug: "french", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ステーキ", slug: "steak", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ハンバーガー", slug: "hamburger", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ハンバーグ", slug: "hamburg", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ピザ", slug: "pizza", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ファミレス", slug: "family_restaurant", category: "食べる", visible: true, parent_slug: "gourmet" },
  # グルメ系 - 中華・アジア
  { name: "中華料理", slug: "chinese", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "餃子", slug: "gyoza", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "韓国料理", slug: "korean", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "タイ料理", slug: "thai", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "インド料理", slug: "indian", category: "食べる", visible: true, parent_slug: "gourmet" },
  { name: "ベトナム料理", slug: "vietnamese", category: "食べる", visible: true, parent_slug: "gourmet" },
  # グルメ系 - その他
  { name: "ファストフード", slug: "fastfood", category: "食べる", visible: true, parent_slug: "gourmet" },
  # グルメ系 - 非表示
  { name: "鍋", slug: "nabe", category: "食べる", visible: false, parent_slug: "gourmet" },
  { name: "定食", slug: "teishoku", category: "食べる", visible: false, parent_slug: "gourmet" },
  { name: "しゃぶしゃぶ", slug: "shabu_shabu", category: "食べる", visible: false, parent_slug: "gourmet" },
  # カフェ・スイーツ系
  { name: "カフェ", slug: "cafe_shop", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "喫茶店", slug: "kissaten", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "パンケーキ", slug: "pancake", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "ケーキ屋", slug: "cake_shop", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "パン屋", slug: "bakery", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "タピオカ", slug: "tapioca", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "ドーナツ", slug: "donut", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "アイスクリーム", slug: "icecream", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "クレープ", slug: "crepe", category: "食べる", visible: true, parent_slug: "cafe" },
  { name: "和菓子", slug: "wagashi", category: "食べる", visible: true, parent_slug: "cafe" },
  # バー系
  { name: "居酒屋", slug: "izakaya", category: "食べる", visible: false, parent_slug: "bar" },
  { name: "スナック", slug: "snack_bar", category: "食べる", visible: false, parent_slug: "bar" },

  # 見る（親ジャンル）
  { name: "観光名所", slug: "sightseeing", category: "見る", visible: true },
  { name: "ミュージアム", slug: "museum_category", category: "見る", visible: true },
  # 見る（独立ジャンル）
  { name: "神社仏閣", slug: "shrine_temple", category: "見る", visible: true },
  { name: "映画館", slug: "movie_theater", category: "見る", visible: false },

  # 観光名所の子ジャンル
  { name: "文化財", slug: "cultural_property", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "夜景スポット", slug: "night_view", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "パワースポット", slug: "power_spot", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "古い町並み", slug: "old_townscape", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "城", slug: "castle", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "史跡", slug: "historic_site", category: "見る", visible: true, parent_slug: "sightseeing" },
  { name: "絶景", slug: "scenic_view", category: "見る", visible: true, parent_slug: "sightseeing" },
  # ミュージアムの子ジャンル
  { name: "美術館", slug: "art_gallery", category: "見る", visible: true, parent_slug: "museum_category" },
  { name: "博物館", slug: "museum", category: "見る", visible: true, parent_slug: "museum_category" },
  { name: "科学館", slug: "science_museum", category: "見る", visible: true, parent_slug: "museum_category" },
  { name: "記念館・資料館", slug: "memorial_hall", category: "見る", visible: true, parent_slug: "museum_category" },

  # お風呂
  { name: "温泉", slug: "onsen", category: "お風呂", visible: true },
  { name: "サウナ", slug: "sauna", category: "お風呂", visible: true },
  { name: "スパ銭", slug: "super_sento", category: "お風呂", visible: true },

  # 動物
  { name: "動物園", slug: "zoo", category: "動物", visible: true },
  { name: "水族館", slug: "aquarium", category: "動物", visible: true },
  { name: "ドッグラン", slug: "dog_run", category: "動物", visible: true },
  { name: "猫カフェ", slug: "cat_cafe", category: "動物", visible: true },
  { name: "犬カフェ", slug: "dog_cafe", category: "動物", visible: true },

  # 自然
  { name: "海・海岸", slug: "sea_coast", category: "自然", visible: true },
  { name: "山・高原", slug: "mountain", category: "自然", visible: true },
  { name: "公園", slug: "park", category: "自然", visible: true },
  { name: "花・庭園", slug: "garden_flower", category: "自然", visible: true },
  { name: "湖・滝", slug: "lake_waterfall", category: "自然", visible: true },
  { name: "牧場", slug: "ranch", category: "自然", visible: true },
  { name: "洞窟", slug: "cave", category: "自然", visible: true },
  { name: "鍾乳洞", slug: "limestone_cave", category: "自然", visible: true },
  { name: "ダム", slug: "dam", category: "自然", visible: true },
  { name: "ロープウェイ・ケーブルカー", slug: "ropeway", category: "自然", visible: false },
  { name: "農園", slug: "farm", category: "自然", visible: true },

  # 遊ぶ
  { name: "テーマパーク", slug: "theme_park", category: "遊ぶ", visible: true },
  { name: "アクティビティ施設", slug: "activity", category: "遊ぶ", visible: true },
  { name: "プール", slug: "water_park", category: "遊ぶ", visible: true },
  { name: "カラオケ", slug: "karaoke", category: "遊ぶ", visible: true },
  { name: "ゲームセンター", slug: "game_center", category: "遊ぶ", visible: true },
  { name: "釣り堀", slug: "fishing_pond", category: "遊ぶ", visible: true },
  { name: "キャンプ場", slug: "campsite", category: "遊ぶ", visible: true },
  { name: "BBQ場", slug: "bbq_site", category: "遊ぶ", visible: true },
  { name: "漫画喫茶", slug: "manga_cafe", category: "遊ぶ", visible: true },
  { name: "ジム", slug: "gym", category: "遊ぶ", visible: false },
  # 運動場（親ジャンル）
  { name: "運動場", slug: "sports_ground", category: "遊ぶ", visible: true },
  { name: "ゴルフ場", slug: "golf_course", category: "遊ぶ", visible: true, parent_slug: "sports_ground" },
  { name: "スキー場", slug: "ski_resort", category: "遊ぶ", visible: true, parent_slug: "sports_ground" },
  { name: "スケート場", slug: "skating_rink", category: "遊ぶ", visible: true, parent_slug: "sports_ground" },
  { name: "フットサル場", slug: "futsal_court", category: "遊ぶ", visible: true, parent_slug: "sports_ground" },
  { name: "ボウリング場", slug: "bowling", category: "遊ぶ", visible: true, parent_slug: "sports_ground" },

  # 買う
  { name: "道の駅・SA/PA", slug: "roadside_station", category: "買う", visible: true },
  { name: "ワイナリー", slug: "winery", category: "買う", visible: true },
  { name: "ショッピング", slug: "shopping", category: "買う", visible: true },
  # ショッピングの子ジャンル
  { name: "雑貨屋", slug: "variety_store", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "お土産屋", slug: "souvenir_shop", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "コンビニ", slug: "convenience_store", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "スーパー", slug: "supermarket", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "デパート", slug: "department_store", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "アウトレット", slug: "outlet", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "直売所", slug: "farm_stand", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "本屋", slug: "bookstore", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "花屋", slug: "flower_shop", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "酒屋", slug: "liquor_store", category: "買う", visible: true, parent_slug: "shopping" },
  { name: "市場・朝市", slug: "market", category: "買う", visible: true, parent_slug: "shopping" },

  # 泊まる
  { name: "宿泊施設", slug: "accommodation", category: "泊まる", visible: true },

  # その他（非表示・AI判定用）
  { name: "施設", slug: "facility", category: "その他", visible: false },
  { name: "駅", slug: "station", category: "その他", visible: false },
  { name: "空港", slug: "airport", category: "その他", visible: false },
  { name: "港", slug: "port", category: "その他", visible: false },
  { name: "駐車場", slug: "parking", category: "その他", visible: false },
  { name: "ガソリンスタンド", slug: "gas_station", category: "その他", visible: false },
  { name: "病院", slug: "hospital", category: "その他", visible: false },
  { name: "学校", slug: "school", category: "その他", visible: false },
  { name: "役所", slug: "government_office", category: "その他", visible: false },
  { name: "警察署", slug: "police", category: "その他", visible: false },
  { name: "消防署", slug: "fire_station", category: "その他", visible: false },
  { name: "郵便局", slug: "post_office", category: "その他", visible: false },
  { name: "図書館", slug: "library", category: "その他", visible: false },
  { name: "銀行", slug: "bank", category: "その他", visible: false },
  { name: "工場", slug: "factory", category: "その他", visible: false },
  { name: "ホームセンター", slug: "home_center", category: "その他", visible: false },
  { name: "ペットショップ", slug: "pet_shop", category: "その他", visible: false },
  { name: "カーショップ", slug: "car_shop", category: "その他", visible: false },
  { name: "事業所", slug: "office", category: "その他", visible: false },
  { name: "家具屋", slug: "furniture_store", category: "その他", visible: false }
].freeze

# 削除対象のジャンル
DELETE_SLUGS = %w[bridge lighthouse factory_tour history_culture castle_historic world_heritage shopping_street observatory_tower].freeze

# 1. 削除対象を先に削除（関連する spot_genres も削除される）
Genre.where(slug: DELETE_SLUGS).destroy_all

# 2. 全ジャンルを作成・更新（parent_id なし）
GENRES.each.with_index(1) do |attrs, position|
  genre = Genre.find_or_initialize_by(slug: attrs[:slug])
  genre.assign_attributes(
    name: attrs[:name],
    category: attrs[:category],
    visible: attrs[:visible],
    position: position,
    parent_id: nil # 一旦リセット
  )
  genre.save!
end

# 3. parent_slug から parent_id を設定
GENRES.each do |attrs|
  next unless attrs[:parent_slug]

  genre = Genre.find_by(slug: attrs[:slug])
  parent = Genre.find_by(slug: attrs[:parent_slug])

  if genre && parent
    genre.update!(parent_id: parent.id)
  end
end

puts "Deleted genres: #{DELETE_SLUGS.join(', ')}"
puts "Created/Updated #{Genre.count} genres"
