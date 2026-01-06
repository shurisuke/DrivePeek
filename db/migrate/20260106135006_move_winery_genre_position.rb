class MoveWineryGenrePosition < ActiveRecord::Migration[8.1]
  # 変更前:
  #   3: 酒屋・ワイナリー, 4: 公園, 5: 海・海岸, 6: 山・高原, ...
  #   19: 道の駅, 20: ショッピング
  # 変更後:
  #   3: 海・海岸, 4: 山・高原, 5: 公園, 6: 湖・滝, ...
  #   19: 道の駅, 20: 酒屋・ワイナリー, 21: ショッピング

  def up
    # 全てのジャンルの position を再設定
    positions = {
      "gourmet" => 1,
      "cafe" => 2,
      "sea_coast" => 3,
      "mountain" => 4,
      "park" => 5,
      "lake_waterfall" => 6,
      "garden_flower" => 7,
      "scenic_view" => 8,
      "sightseeing" => 9,
      "shrine_temple" => 10,
      "castle_historic" => 11,
      "museum" => 12,
      "theme_park" => 13,
      "zoo_aquarium" => 14,
      "activity" => 15,
      "onsen" => 16,
      "accommodation" => 17,
      "roadside_station" => 18,
      "winery" => 19,
      "shopping" => 20
    }

    positions.each do |slug, pos|
      execute "UPDATE genres SET position = #{pos} WHERE slug = '#{slug}'"
    end
  end

  def down
    # 元の position に戻す
    positions = {
      "gourmet" => 1,
      "cafe" => 2,
      "winery" => 3,
      "park" => 4,
      "sea_coast" => 5,
      "mountain" => 6,
      "lake_waterfall" => 7,
      "garden_flower" => 8,
      "scenic_view" => 9,
      "sightseeing" => 10,
      "shrine_temple" => 11,
      "castle_historic" => 12,
      "museum" => 13,
      "theme_park" => 14,
      "zoo_aquarium" => 15,
      "activity" => 16,
      "onsen" => 17,
      "accommodation" => 18,
      "roadside_station" => 19,
      "shopping" => 20
    }

    positions.each do |slug, pos|
      execute "UPDATE genres SET position = #{pos} WHERE slug = '#{slug}'"
    end
  end
end
