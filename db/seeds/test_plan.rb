# テストプラン作成スクリプト

# テストユーザー取得（最初のユーザー）
user = User.first
unless user
  puts "ユーザーが存在しません。先にユーザーを作成してください。"
  exit
end

puts "ユーザー: #{user.email}"

# 新しいプランを作成
plan = user.plans.create!(title: "テスト：東京ドライブプラン")
puts "プラン作成: #{plan.title} (ID: #{plan.id})"

# 出発地点を作成（東京駅）
start_point = plan.create_start_point!(
  lat: 35.6812,
  lng: 139.7671,
  address: "東京都千代田区丸の内1丁目",
  departure_time: Time.zone.parse("09:00")
)
puts "出発地点: #{start_point.address}"

# スポットを作成
spots_data = [
  { place_id: "test_spot_1", name: "浅草寺", address: "東京都台東区浅草2-3-1", lat: 35.7148, lng: 139.7967 },
  { place_id: "test_spot_2", name: "東京スカイツリー", address: "東京都墨田区押上1-1-2", lat: 35.7101, lng: 139.8107 },
  { place_id: "test_spot_3", name: "お台場海浜公園", address: "東京都港区台場1丁目", lat: 35.6299, lng: 139.7753 }
]

spots_data.each_with_index do |data, i|
  spot = Spot.find_or_create_by!(place_id: data[:place_id]) do |s|
    s.name = data[:name]
    s.address = data[:address]
    s.lat = data[:lat]
    s.lng = data[:lng]
  end

  plan_spot = plan.plan_spots.create!(
    spot: spot,
    position: i + 1,
    stay_duration: 60,
    move_time: 20,
    move_distance: 5.0
  )
  puts "スポット#{i + 1}: #{spot.name}"
end

# 帰宅地点を作成（東京駅に戻る）
goal_point = plan.create_goal_point!(
  lat: 35.6812,
  lng: 139.7671,
  address: "東京都千代田区丸の内1丁目"
)
puts "帰宅地点: #{goal_point.address}"

puts ""
puts "✅ テストプラン作成完了!"
puts "   編集URL: /plans/#{plan.id}/edit"
