# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiArea::SpotFinder, type: :service do
  describe "#fetch_for_slots" do
    let(:center_lat) { 35.6762 }
    let(:center_lng) { 139.6503 }
    let(:radius_km) { 10.0 }
    let(:finder) { described_class.new(center_lat, center_lng, radius_km) }

    let!(:genre_gourmet) { create(:genre, name: "グルメ", slug: "gourmet") }
    let!(:genre_onsen) { create(:genre, name: "温泉", slug: "onsen") }

    context "円内にスポットがある場合" do
      let!(:spot_in_circle) do
        create(:spot, lat: 35.6770, lng: 139.6510).tap do |s|
          s.genres << genre_gourmet
        end
      end

      let!(:spot_outside) do
        create(:spot, lat: 36.5, lng: 140.5).tap do |s|
          s.genres << genre_gourmet
        end
      end

      it "指定ジャンルのスロット候補を返す" do
        slots = [ { genre_id: genre_gourmet.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("グルメ")
        expect(result.first[:candidates].map { |c| c[:id] }).to include(spot_in_circle.id)
        expect(result.first[:candidates].map { |c| c[:id] }).not_to include(spot_outside.id)
      end

      it "複数スロットに対応する" do
        spot_onsen = create(:spot, lat: 35.6780, lng: 139.6520)
        spot_onsen.genres << genre_onsen

        slots = [ { genre_id: genre_gourmet.id }, { genre_id: genre_onsen.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.length).to eq(2)
        expect(result.map { |r| r[:genre_name] }).to contain_exactly("グルメ", "温泉")
      end
    end

    context "ジャンルが見つからない場合" do
      it "そのスロットをスキップする" do
        slots = [ { genre_id: 99999 } ]
        result = finder.fetch_for_slots(slots)

        expect(result).to be_empty
      end
    end

    context "円内に該当スポットがない場合" do
      it "そのスロットをスキップする" do
        # 円外にのみスポットがある
        create(:spot, lat: 40.0, lng: 145.0).tap { |s| s.genres << genre_gourmet }

        slots = [ { genre_id: genre_gourmet.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result).to be_empty
      end
    end

    context "文字列キーのスロットの場合" do
      let!(:spot) do
        create(:spot, lat: 35.6770, lng: 139.6510).tap { |s| s.genres << genre_gourmet }
      end

      it "文字列キーでも動作する" do
        slots = [ { "genre_id" => genre_gourmet.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.length).to eq(1)
      end
    end
  end

  describe "#fetch_for_genre" do
    let(:center_lat) { 35.6762 }
    let(:center_lng) { 139.6503 }
    let(:radius_km) { 10.0 }
    let(:finder) { described_class.new(center_lat, center_lng, radius_km) }

    let!(:genre) { create(:genre, name: "グルメ", slug: "gourmet") }

    context "円内にスポットがある場合" do
      let!(:spot1) { create(:spot, lat: 35.6770, lng: 139.6510) }
      let!(:spot2) { create(:spot, lat: 35.6780, lng: 139.6520) }
      let!(:spot_outside) { create(:spot, lat: 40.0, lng: 145.0) }

      before do
        spot1.genres << genre
        spot2.genres << genre
        spot_outside.genres << genre
      end

      it "指定件数の候補を返す" do
        result = finder.fetch_for_genre(genre, 2)

        expect(result.length).to eq(2)
        expect(result.map { |s| s[:id] }).to include(spot1.id, spot2.id)
        expect(result.map { |s| s[:id] }).not_to include(spot_outside.id)
      end

      it "候補にはスポット情報が含まれる" do
        result = finder.fetch_for_genre(genre, 1)

        spot = result.first
        expect(spot).to include(:id, :name, :address, :lat, :lng, :place_id, :genres)
      end
    end

    context "人気順ソート" do
      let!(:popular_spot) { create(:spot, lat: 35.6770, lng: 139.6510) }
      let!(:normal_spot) { create(:spot, lat: 35.6780, lng: 139.6520) }

      before do
        popular_spot.genres << genre
        normal_spot.genres << genre
        # popular_spotに複数のいいねを追加
        3.times { create(:favorite_spot, spot: popular_spot) }
      end

      it "お気に入り数順で返す" do
        result = finder.fetch_for_genre(genre, 2)

        # 人気スポットが先頭（お気に入り数が多い順）
        ids = result.map { |s| s[:id] }
        expect(ids.first).to eq(popular_spot.id)
      end
    end

    context "該当スポットがない場合" do
      it "空配列を返す" do
        result = finder.fetch_for_genre(genre, 5)

        expect(result).to eq([])
      end
    end
  end

  describe "距離計算" do
    let(:finder) { described_class.new(35.6762, 139.6503, 5.0) }
    let!(:genre) { create(:genre) }

    it "半径5km以内のスポットを取得する" do
      # 約3km離れたスポット（緯度で約0.027度）
      near_spot = create(:spot, lat: 35.7032, lng: 139.6503)
      near_spot.genres << genre

      # 約10km離れたスポット
      far_spot = create(:spot, lat: 35.7662, lng: 139.6503)
      far_spot.genres << genre

      result = finder.fetch_for_genre(genre, 10)

      expect(result.map { |s| s[:id] }).to include(near_spot.id)
      expect(result.map { |s| s[:id] }).not_to include(far_spot.id)
    end
  end
end
