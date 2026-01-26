# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spot, type: :model do
  describe "associations" do
    it { should have_many(:like_spots).dependent(:destroy) }
    it { should have_many(:liked_by_users).through(:like_spots).source(:user) }
    it { should have_many(:plan_spots).dependent(:destroy) }
    it { should have_many(:plans).through(:plan_spots) }
    it { should have_many(:spot_genres).dependent(:destroy) }
    it { should have_many(:genres).through(:spot_genres) }
    it { should have_many(:spot_comments).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:spot) }

    it { should validate_presence_of(:place_id) }
    it { should validate_uniqueness_of(:place_id) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:lat) }
    it { should validate_presence_of(:lng) }
  end

  describe "factory" do
    it "有効なファクトリを持つ" do
      expect(build(:spot)).to be_valid
    end

    it "シーケンスでユニークなplace_idを生成する" do
      spot1 = create(:spot)
      spot2 = create(:spot)
      expect(spot1.place_id).not_to eq(spot2.place_id)
    end
  end

  describe "scopes" do
    describe ".nearby" do
      let!(:center_spot) { create(:spot, lat: 35.6762, lng: 139.6503) }
      let!(:nearby_spot) { create(:spot, lat: 35.6763, lng: 139.6504) }
      let!(:far_spot) { create(:spot, lat: 36.0, lng: 140.0) }

      it "閾値内のスポットを返す" do
        result = Spot.nearby(lat: 35.6762, lng: 139.6503)
        expect(result).to include(center_spot, nearby_spot)
        expect(result).not_to include(far_spot)
      end

      it "カスタム閾値を指定できる" do
        result = Spot.nearby(lat: 35.6762, lng: 139.6503, threshold: 0.5)
        expect(result).to include(center_spot, nearby_spot, far_spot)
      end
    end

    describe ".search_keyword" do
      let!(:spot) { create(:spot, name: "東京タワー", address: "東京都港区") }

      it "名前で検索できる" do
        expect(Spot.search_keyword("タワー")).to include(spot)
      end

      it "住所で検索できる" do
        expect(Spot.search_keyword("港区")).to include(spot)
      end

      it "空のキーワードは全件返す" do
        expect(Spot.search_keyword("")).to include(spot)
        expect(Spot.search_keyword(nil)).to include(spot)
      end
    end

    describe ".liked_by" do
      let(:user) { create(:user) }
      let!(:liked_spot) { create(:spot) }
      let!(:unliked_spot) { create(:spot) }

      before { create(:like_spot, user: user, spot: liked_spot) }

      it "指定ユーザーがお気に入りしたスポットのみ返す" do
        result = Spot.liked_by(user)
        expect(result).to include(liked_spot)
        expect(result).not_to include(unliked_spot)
      end

      it "nilの場合は空のRelationを返す" do
        expect(Spot.liked_by(nil)).to be_empty
      end
    end

    describe ".filter_by_cities" do
      let!(:tokyo_spot) { create(:spot, prefecture: "東京都", city: "港区") }
      let!(:osaka_spot) { create(:spot, prefecture: "大阪府", city: "大阪市") }

      it "都道府県/市区町村で絞り込む" do
        result = Spot.filter_by_cities([ "東京都/港区" ])
        expect(result).to include(tokyo_spot)
        expect(result).not_to include(osaka_spot)
      end

      it "都道府県のみで絞り込む" do
        result = Spot.filter_by_cities([ "東京都" ])
        expect(result).to include(tokyo_spot)
        expect(result).not_to include(osaka_spot)
      end

      it "複数の市区町村で絞り込む" do
        result = Spot.filter_by_cities([ "東京都/港区", "大阪府/大阪市" ])
        expect(result).to include(tokyo_spot, osaka_spot)
      end

      it "空の配列は全件返す" do
        expect(Spot.filter_by_cities([])).to include(tokyo_spot, osaka_spot)
      end
    end

    describe ".filter_by_genres" do
      let(:parent_genre) { create(:genre, name: "グルメ") }
      let(:child_genre) { create(:genre, name: "ラーメン", parent: parent_genre) }
      let!(:spot_with_parent) { create(:spot) }
      let!(:spot_with_child) { create(:spot) }
      let!(:spot_without_genre) { create(:spot) }

      before do
        spot_with_parent.genres << parent_genre
        spot_with_child.genres << child_genre
      end

      it "親ジャンル選択時は子ジャンルも含める" do
        result = Spot.filter_by_genres([ parent_genre.id ])
        expect(result).to include(spot_with_parent, spot_with_child)
        expect(result).not_to include(spot_without_genre)
      end

      it "空の配列は全件返す" do
        expect(Spot.filter_by_genres([])).to include(spot_with_parent, spot_with_child, spot_without_genre)
      end
    end
  end

  describe ".find_or_create_from_location" do
    let(:name) { "テストスポット" }
    let(:address) { "東京都渋谷区" }
    let(:lat) { 35.6580 }
    let(:lng) { 139.7016 }

    before do
      stub_google_places_api
      stub_google_geocoding_api
      # GooglePlacesAdapterのモック
      allow(GooglePlacesAdapter).to receive(:find_place).and_return({
        place_id: "ChIJtest_new_place",
        name: name,
        lat: lat,
        lng: lng
      })
    end

    context "近傍に既存スポットがある場合" do
      let!(:existing_spot) { create(:spot, lat: lat, lng: lng) }

      it "既存スポットを返す" do
        result = Spot.find_or_create_from_location(name: name, address: address, lat: lat, lng: lng)
        expect(result).to eq(existing_spot)
      end
    end

    context "近傍にスポットがない場合" do
      it "新しいスポットを作成する" do
        expect {
          Spot.find_or_create_from_location(name: name, address: address, lat: lat, lng: lng)
        }.to change(Spot, :count).by(1)
      end
    end

    context "nameが空の場合" do
      it "nilを返す" do
        result = Spot.find_or_create_from_location(name: "", address: address, lat: lat, lng: lng)
        expect(result).to be_nil
      end
    end

    context "座標が0の場合" do
      it "nilを返す" do
        result = Spot.find_or_create_from_location(name: name, address: address, lat: 0, lng: 0)
        expect(result).to be_nil
      end
    end
  end

  describe ".cities_by_prefecture" do
    before do
      create(:spot, prefecture: "東京都", city: "港区")
      create(:spot, prefecture: "東京都", city: "渋谷区")
      create(:spot, prefecture: "大阪府", city: "大阪市")
      Rails.cache.clear
    end

    it "都道府県ごとの市区町村リストを返す" do
      result = Spot.cities_by_prefecture

      expect(result["東京都"]).to include("港区", "渋谷区")
      expect(result["大阪府"]).to include("大阪市")
    end

    it "prefecture/cityが空のレコードを除外する" do
      stub_google_geocoding_api
      create(:spot, prefecture: nil, city: nil)
      create(:spot, prefecture: "", city: "")
      Rails.cache.clear

      result = Spot.cities_by_prefecture

      # nilや空文字のレコードは含まれない
      expect(result.keys).to match_array([ "東京都", "大阪府" ])
    end
  end

  describe ".clear_cities_cache" do
    it "キャッシュをクリアする" do
      Rails.cache.write(Spot::CITIES_CACHE_KEY, { "テスト" => [ "市" ] })

      Spot.clear_cities_cache

      expect(Rails.cache.read(Spot::CITIES_CACHE_KEY)).to be_nil
    end
  end

  describe "#detect_genres!" do
    let(:spot) { create(:spot) }
    let!(:genre1) { create(:genre, name: "カフェ") }
    let!(:genre2) { create(:genre, name: "レストラン") }
    let!(:facility_genre) { create(:genre, slug: "facility", name: "施設") }

    before do
      stub_openai_chat_api
    end

    context "ジャンルが2つ未満の場合" do
      it "GenreDetectorを呼び出す" do
        allow(GenreDetector).to receive(:detect).and_return([ genre1.id, genre2.id ])

        result = spot.detect_genres!

        expect(result).to be true
        expect(spot.genres.reload.pluck(:id)).to include(genre1.id, genre2.id)
      end
    end

    context "ジャンルが2つ以上の場合" do
      before do
        spot.genres << genre1
        spot.genres << genre2
      end

      it "falseを返す（判定スキップ）" do
        expect(spot.detect_genres!).to be false
      end
    end

    context "GenreDetectorが空配列を返す場合" do
      it "facilityジャンルをフォールバックとして設定する" do
        allow(GenreDetector).to receive(:detect).and_return([])

        spot.detect_genres!

        expect(spot.genres.reload.pluck(:slug)).to include("facility")
      end
    end
  end

  describe "PROXIMITY_THRESHOLD" do
    it "0.001度である" do
      expect(Spot::PROXIMITY_THRESHOLD).to eq(0.001)
    end
  end
end
