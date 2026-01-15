class AddSightseeingAndNatureGenres < ActiveRecord::Migration[8.1]
  NEW_GENRES = [
    # 見る - 展望台・タワー（表示）
    { slug: "observatory_tower", name: "展望台・タワー", category: "見る", visible: true },

    # 見る - 観光名所の細分化（非表示）
    { slug: "old_townscape", name: "古い町並み", category: "見る", visible: false },
    { slug: "science_museum", name: "科学館", category: "見る", visible: false },
    { slug: "memorial_hall", name: "記念館・資料館", category: "見る", visible: false },
    { slug: "lighthouse", name: "灯台", category: "見る", visible: false },
    { slug: "bridge", name: "橋", category: "見る", visible: false },
    { slug: "dam", name: "ダム", category: "見る", visible: false },
    { slug: "factory_tour", name: "工場見学", category: "見る", visible: false },
    { slug: "night_view", name: "夜景スポット", category: "見る", visible: false },
    { slug: "power_spot", name: "パワースポット", category: "見る", visible: false },
    { slug: "world_heritage", name: "世界遺産", category: "見る", visible: false },
    { slug: "ropeway", name: "ロープウェイ・ケーブルカー", category: "見る", visible: false },
    { slug: "market", name: "市場・朝市", category: "見る", visible: false },
    { slug: "shopping_street", name: "商店街", category: "見る", visible: false },

    # 自然 - 細分化（非表示）
    { slug: "ranch", name: "牧場", category: "自然", visible: false },
    { slug: "cave", name: "洞窟・鍾乳洞", category: "自然", visible: false }
  ].freeze

  def up
    max_position = Genre.maximum(:position) || 0

    NEW_GENRES.each.with_index(1) do |attrs, index|
      next if Genre.exists?(slug: attrs[:slug])

      Genre.create!(
        slug: attrs[:slug],
        name: attrs[:name],
        category: attrs[:category],
        visible: attrs[:visible],
        position: max_position + index
      )
    end
  end

  def down
    slugs = NEW_GENRES.map { |g| g[:slug] }
    Genre.where(slug: slugs).destroy_all
  end
end
