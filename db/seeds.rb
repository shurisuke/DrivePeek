# ジャンルマスタデータ
GENRES = [
  # 食
  { name: "グルメ", slug: "gourmet" },
  { name: "カフェ・スイーツ", slug: "cafe" },
  { name: "酒屋・ワイナリー", slug: "winery" },
  # 自然・景観
  { name: "公園", slug: "park" },
  { name: "海・海岸", slug: "sea_coast" },
  { name: "山・高原", slug: "mountain" },
  { name: "湖・滝", slug: "lake_waterfall" },
  { name: "花・庭園", slug: "garden_flower" },
  { name: "絶景・展望", slug: "scenic_view" },
  # 観光・文化
  { name: "観光名所", slug: "sightseeing" },
  { name: "神社仏閣", slug: "shrine_temple" },
  { name: "城・史跡", slug: "castle_historic" },
  { name: "博物館・美術館", slug: "museum" },
  # レジャー・体験
  { name: "テーマパーク", slug: "theme_park" },
  { name: "動物園・水族館", slug: "zoo_aquarium" },
  { name: "アクティビティ", slug: "activity" },
  # 休憩・宿泊
  { name: "温泉・スパ", slug: "onsen" },
  { name: "宿泊施設", slug: "accommodation" },
  # 買い物
  { name: "道の駅・SA/PA", slug: "roadside_station" },
  { name: "ショッピング", slug: "shopping" }
].freeze

GENRES.each.with_index(1) do |attrs, position|
  Genre.find_or_create_by!(slug: attrs[:slug]) do |genre|
    genre.name = attrs[:name]
    genre.position = position
  end
end

puts "Created #{Genre.count} genres"
