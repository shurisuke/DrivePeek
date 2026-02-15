# ジャンルマスタデータ
# category: カテゴリ名, visible: UI表示するかどうか, parent_slug: 親ジャンル, emoji: マーカー表示用絵文字
GENRES = [
  # ==========================================
  # 食べる
  # ==========================================
  # 親ジャンル
  { name: "グルメ", slug: "gourmet", category: "食べる", visible: true, emoji: "🍴" },
  { name: "カフェ・スイーツ", slug: "cafe", category: "食べる", visible: true, emoji: "☕" },
  { name: "バー", slug: "bar", category: "食べる", visible: false, emoji: "🍷" },
  # グルメ系 - 人気の定番
  { name: "ラーメン", slug: "ramen", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "寿司", slug: "sushi", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "焼肉", slug: "yakiniku", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "カレー", slug: "curry", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  # グルメ系 - 和食
  { name: "和食", slug: "washoku", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "うどん・そば", slug: "udon_soba", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "天ぷら", slug: "tempura", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "とんかつ", slug: "tonkatsu", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "焼き鳥", slug: "yakitori", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "海鮮", slug: "seafood", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "お好み焼き", slug: "okonomiyaki", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "たこ焼き", slug: "takoyaki", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "牛丼", slug: "gyudon", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  # グルメ系 - 洋食
  { name: "イタリアン", slug: "italian", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "フレンチ", slug: "french", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ステーキ", slug: "steak", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ハンバーガー", slug: "hamburger", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ハンバーグ", slug: "hamburg", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ピザ", slug: "pizza", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ファミレス", slug: "family_restaurant", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  # グルメ系 - 中華・アジア
  { name: "中華料理", slug: "chinese", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "餃子", slug: "gyoza", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "韓国料理", slug: "korean", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "タイ料理", slug: "thai", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "インド料理", slug: "indian", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  { name: "ベトナム料理", slug: "vietnamese", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  # グルメ系 - その他
  { name: "ファストフード", slug: "fastfood", category: "食べる", visible: true, parent_slug: "gourmet", emoji: "🍴" },
  # グルメ系 - 非表示
  { name: "鍋", slug: "nabe", category: "食べる", visible: false, parent_slug: "gourmet", emoji: "🍴" },
  { name: "定食", slug: "teishoku", category: "食べる", visible: false, parent_slug: "gourmet", emoji: "🍴" },
  { name: "しゃぶしゃぶ", slug: "shabu_shabu", category: "食べる", visible: false, parent_slug: "gourmet", emoji: "🍴" },
  # カフェ・スイーツ系
  { name: "カフェ", slug: "cafe_shop", category: "食べる", visible: true, parent_slug: "cafe", emoji: "☕" },
  { name: "喫茶店", slug: "kissaten", category: "食べる", visible: true, parent_slug: "cafe", emoji: "☕" },
  { name: "パンケーキ", slug: "pancake", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🥞" },
  { name: "ケーキ屋", slug: "cake_shop", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🍰" },
  { name: "パン屋", slug: "bakery", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🥐" },
  { name: "タピオカ", slug: "tapioca", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🧋" },
  { name: "ドーナツ", slug: "donut", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🍩" },
  { name: "アイスクリーム", slug: "icecream", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🍦" },
  { name: "クレープ", slug: "crepe", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🥞" },
  { name: "和菓子", slug: "wagashi", category: "食べる", visible: true, parent_slug: "cafe", emoji: "🍡" },
  # バー系
  { name: "居酒屋", slug: "izakaya", category: "食べる", visible: false, parent_slug: "bar", emoji: "🍴" },
  { name: "スナック", slug: "snack_bar", category: "食べる", visible: false, parent_slug: "bar", emoji: "🍷" },

  # ==========================================
  # 見る
  # ==========================================
  # 親ジャンル
  { name: "観光名所", slug: "sightseeing", category: "見る", visible: true, emoji: "🏛️" },
  { name: "ミュージアム", slug: "museum_category", category: "見る", visible: true, emoji: "🏛️" },
  # 独立ジャンル
  { name: "神社仏閣", slug: "shrine_temple", category: "見る", visible: true, emoji: "⛩️" },
  { name: "映画館", slug: "movie_theater", category: "見る", visible: false },
  # 観光名所の子ジャンル
  { name: "文化財", slug: "cultural_property", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏛️" },
  { name: "夜景スポット", slug: "night_view", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🌃" },
  { name: "城", slug: "castle", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏯" },
  { name: "史跡", slug: "historic_site", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🏛️" },
  { name: "絶景", slug: "scenic_view", category: "見る", visible: true, parent_slug: "sightseeing", emoji: "🌅" },
  # ミュージアムの子ジャンル
  { name: "美術館", slug: "art_gallery", category: "見る", visible: true, parent_slug: "museum_category", emoji: "🏛️" },
  { name: "博物館", slug: "museum", category: "見る", visible: true, parent_slug: "museum_category", emoji: "🏛️" },
  { name: "科学館", slug: "science_museum", category: "見る", visible: true, parent_slug: "museum_category", emoji: "🏛️" },
  { name: "記念館・資料館", slug: "memorial_hall", category: "見る", visible: true, parent_slug: "museum_category", emoji: "🏛️" },

  # ==========================================
  # お風呂
  # ==========================================
  { name: "温泉", slug: "onsen", category: "お風呂", visible: true, emoji: "♨️" },
  { name: "サウナ", slug: "sauna", category: "お風呂", visible: true, emoji: "♨️" },
  { name: "スパ銭", slug: "super_sento", category: "お風呂", visible: true, emoji: "♨️" },

  # ==========================================
  # 動物
  # ==========================================
  { name: "動物園", slug: "zoo", category: "動物", visible: true, emoji: "🦁" },
  { name: "水族館", slug: "aquarium", category: "動物", visible: true, emoji: "🐬" },

  # ==========================================
  # 自然
  # ==========================================
  { name: "海・海岸", slug: "sea_coast", category: "自然", visible: true, emoji: "🏖️" },
  { name: "山・高原", slug: "mountain", category: "自然", visible: true, emoji: "⛰️" },
  { name: "公園", slug: "park", category: "自然", visible: true, emoji: "🌳" },
  { name: "花・庭園", slug: "garden_flower", category: "自然", visible: true, emoji: "🌳" },
  { name: "湖・滝", slug: "lake_waterfall", category: "自然", visible: true, emoji: "💧" },
  { name: "洞窟", slug: "cave", category: "自然", visible: true, emoji: "🕳️" },
  { name: "鍾乳洞", slug: "limestone_cave", category: "自然", visible: true, emoji: "🕳️" },
  { name: "ダム", slug: "dam", category: "自然", visible: true, emoji: "💧" },

  # ==========================================
  # 遊ぶ
  # ==========================================
  { name: "テーマパーク", slug: "theme_park", category: "遊ぶ", visible: true, emoji: "🎢" },
  { name: "アクティビティ施設", slug: "activity", category: "遊ぶ", visible: true, emoji: "🪂" },
  { name: "プール", slug: "water_park", category: "遊ぶ", visible: true, emoji: "💧" },
  { name: "釣り堀", slug: "fishing_pond", category: "遊ぶ", visible: true, emoji: "🎣" },

  # ==========================================
  # 買う
  # ==========================================
  { name: "道の駅・SA/PA", slug: "roadside_station", category: "買う", visible: true, emoji: "🚗" },
  { name: "ショッピング", slug: "shopping", category: "買う", visible: true, emoji: "🛍️" },
  # ショッピングの子ジャンル
  { name: "雑貨屋", slug: "variety_store", category: "買う", visible: true, parent_slug: "shopping", emoji: "🛍️" },
  { name: "お土産屋", slug: "souvenir_shop", category: "買う", visible: true, parent_slug: "shopping", emoji: "🛍️" },
  { name: "コンビニ", slug: "convenience_store", category: "買う", visible: true, parent_slug: "shopping", emoji: "🏪" },
  { name: "スーパー", slug: "supermarket", category: "買う", visible: true, parent_slug: "shopping", emoji: "🛒" },
  { name: "デパート", slug: "department_store", category: "買う", visible: true, parent_slug: "shopping", emoji: "🏬" },
  { name: "アウトレット", slug: "outlet", category: "買う", visible: true, parent_slug: "shopping", emoji: "👗" },
  { name: "直売所", slug: "farm_stand", category: "買う", visible: true, parent_slug: "shopping", emoji: "🥬" },
  { name: "洋服屋", slug: "clothing_store", category: "買う", visible: true, parent_slug: "shopping", emoji: "👚" },
  { name: "花屋", slug: "flower_shop", category: "買う", visible: true, parent_slug: "shopping", emoji: "💐" },
  { name: "酒屋", slug: "liquor_store", category: "買う", visible: true, parent_slug: "shopping", emoji: "🍾" },
  { name: "市場・朝市", slug: "market", category: "買う", visible: true, parent_slug: "shopping", emoji: "🛒" },

  # ==========================================
  # 泊まる
  # ==========================================
  { name: "宿泊施設", slug: "accommodation", category: "泊まる", visible: true, emoji: "🏨" },

  # ==========================================
  # その他（非表示・AI判定用）
  # ==========================================
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
  # 元「遊ぶ」から移動（非表示）
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
  # 運動場（親ジャンル）
  { name: "運動場", slug: "sports_ground", category: "その他", visible: false, emoji: "⚽" },
  { name: "ゴルフ場", slug: "golf_course", category: "その他", visible: false, parent_slug: "sports_ground", emoji: "⛳" },
  { name: "スキー場", slug: "ski_resort", category: "その他", visible: false, parent_slug: "sports_ground", emoji: "⛷️" },
  { name: "スケート場", slug: "skating_rink", category: "その他", visible: false, parent_slug: "sports_ground", emoji: "⛸️" },
  { name: "フットサル場", slug: "futsal_court", category: "その他", visible: false, parent_slug: "sports_ground", emoji: "⚽" },
  { name: "ボウリング場", slug: "bowling", category: "その他", visible: false, parent_slug: "sports_ground", emoji: "🎳" }
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
