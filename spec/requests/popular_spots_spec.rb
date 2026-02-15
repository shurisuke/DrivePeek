# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PopularSpots", type: :request do
  describe "GET /popular_spots" do
    let!(:user) { create(:user) }
    let!(:genre) { create(:genre, name: "カフェ", emoji: "☕") }
    let!(:spot1) { create(:spot, name: "人気カフェ", lat: 35.68, lng: 139.76, genres: [ genre ]) }
    let!(:spot2) { create(:spot, name: "普通のカフェ", lat: 35.69, lng: 139.77, genres: [ genre ]) }
    let!(:spot_outside) { create(:spot, name: "範囲外", lat: 36.0, lng: 140.0, genres: [ genre ]) }

    before do
      # favorites_countはCOUNTで計算されるので、FavoriteSpotを作成
      10.times { create(:favorite_spot, user: create(:user), spot: spot1) }
      5.times { create(:favorite_spot, user: create(:user), spot: spot2) }
      100.times { create(:favorite_spot, user: create(:user), spot: spot_outside) }
    end

    it "指定範囲内の人気スポットをJSON形式で返す" do
      get popular_spots_path, params: {
        north: 35.70,
        south: 35.67,
        east: 139.78,
        west: 139.75,
        limit: 10
      }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["spots"]).to be_an(Array)
      expect(json["spots"].size).to eq(2)

      # 人気順でソートされていることを確認
      names = json["spots"].map { |s| s["name"] }
      expect(names).to eq([ "人気カフェ", "普通のカフェ" ])
    end

    it "スポット情報に必要なフィールドが含まれる" do
      get popular_spots_path, params: {
        north: 35.70,
        south: 35.67,
        east: 139.78,
        west: 139.75
      }

      json = JSON.parse(response.body)
      spot = json["spots"].first

      expect(spot).to include(
        "id" => be_a(Integer),
        "name" => "人気カフェ",
        "lat" => 35.68,
        "lng" => 139.76,
        "favorites_count" => 10,
        "emoji" => "☕"
      )
    end

    it "genre_idsでフィルタリングできる" do
      other_genre = create(:genre, name: "ラーメン", emoji: "🍜")
      ramen_spot = create(:spot, name: "ラーメン店", lat: 35.685, lng: 139.765, genres: [ other_genre ])
      20.times { create(:favorite_spot, user: create(:user), spot: ramen_spot) }

      get popular_spots_path, params: {
        north: 35.70,
        south: 35.67,
        east: 139.78,
        west: 139.75,
        genre_ids: [ other_genre.id ]
      }

      json = JSON.parse(response.body)
      expect(json["spots"].size).to eq(1)
      expect(json["spots"].first["name"]).to eq("ラーメン店")
    end

    it "limitで取得件数を制限できる" do
      get popular_spots_path, params: {
        north: 35.70,
        south: 35.67,
        east: 139.78,
        west: 139.75,
        limit: 1
      }

      json = JSON.parse(response.body)
      expect(json["spots"].size).to eq(1)
    end

    it "ジャンルがないスポットはデフォルト絵文字を返す" do
      spot_no_genre = create(:spot, name: "ジャンルなし", lat: 35.682, lng: 139.762)
      3.times { create(:favorite_spot, user: create(:user), spot: spot_no_genre) }

      get popular_spots_path, params: {
        north: 35.70,
        south: 35.67,
        east: 139.78,
        west: 139.75
      }

      json = JSON.parse(response.body)
      no_genre_spot = json["spots"].find { |s| s["name"] == "ジャンルなし" }
      expect(no_genre_spot["emoji"]).to eq("✨")
    end
  end
end
