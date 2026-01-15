class AddDetailedFoodGenres < ActiveRecord::Migration[8.1]
  DETAILED_GENRES = [
    # グルメ細分化 (26個)
    { slug: "ramen", name: "ラーメン", category: "食べる" },
    { slug: "sushi", name: "寿司", category: "食べる" },
    { slug: "yakiniku", name: "焼肉", category: "食べる" },
    { slug: "washoku", name: "和食", category: "食べる" },
    { slug: "chinese", name: "中華料理", category: "食べる" },
    { slug: "italian", name: "イタリアン", category: "食べる" },
    { slug: "curry", name: "カレー", category: "食べる" },
    { slug: "udon_soba", name: "うどん・そば", category: "食べる" },
    { slug: "fastfood", name: "ファストフード", category: "食べる" },
    { slug: "korean", name: "韓国料理", category: "食べる" },
    { slug: "thai", name: "タイ料理", category: "食べる" },
    { slug: "indian", name: "インド料理", category: "食べる" },
    { slug: "vietnamese", name: "ベトナム料理", category: "食べる" },
    { slug: "french", name: "フレンチ", category: "食べる" },
    { slug: "yakitori", name: "焼き鳥", category: "食べる" },
    { slug: "tempura", name: "天ぷら", category: "食べる" },
    { slug: "tonkatsu", name: "とんかつ", category: "食べる" },
    { slug: "gyoza", name: "餃子", category: "食べる" },
    { slug: "steak", name: "ステーキ", category: "食べる" },
    { slug: "seafood", name: "海鮮", category: "食べる" },
    { slug: "nabe", name: "鍋", category: "食べる" },
    { slug: "okonomiyaki", name: "お好み焼き", category: "食べる" },
    { slug: "hamburger", name: "ハンバーガー", category: "食べる" },
    { slug: "pizza", name: "ピザ", category: "食べる" },
    { slug: "gyudon", name: "牛丼", category: "食べる" },
    { slug: "teishoku", name: "定食", category: "食べる" },

    # カフェ・スイーツ細分化 (9個)
    { slug: "kissaten", name: "喫茶店", category: "食べる" },
    { slug: "pancake", name: "パンケーキ", category: "食べる" },
    { slug: "cake_shop", name: "ケーキ屋", category: "食べる" },
    { slug: "bakery", name: "パン屋", category: "食べる" },
    { slug: "tapioca", name: "タピオカ", category: "食べる" },
    { slug: "donut", name: "ドーナツ", category: "食べる" },
    { slug: "icecream", name: "アイスクリーム", category: "食べる" },
    { slug: "crepe", name: "クレープ", category: "食べる" },
    { slug: "wagashi", name: "和菓子", category: "食べる" },

    # バー細分化 (3個)
    { slug: "izakaya", name: "居酒屋", category: "食べる" },
    { slug: "snack_bar", name: "スナック", category: "食べる" },
    { slug: "pub", name: "パブ", category: "食べる" }
  ].freeze

  def up
    Genre.reset_column_information
    max_position = Genre.maximum(:position) || 0

    DETAILED_GENRES.each.with_index(1) do |attrs, index|
      next if Genre.exists?(slug: attrs[:slug])

      Genre.create!(
        slug: attrs[:slug],
        name: attrs[:name],
        category: attrs[:category],
        visible: false,
        position: max_position + index
      )
    end
  end

  def down
    slugs = DETAILED_GENRES.map { |g| g[:slug] }
    Genre.where(slug: slugs).destroy_all
  end
end
