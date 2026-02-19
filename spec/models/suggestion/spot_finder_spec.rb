# frozen_string_literal: true

require "rails_helper"

RSpec.describe Suggestion::SpotFinder, type: :service do
  let(:center_lat) { 35.6762 }
  let(:center_lng) { 139.6503 }
  let(:radius_km) { 10.0 }
  let(:finder) { described_class.new(center_lat, center_lng, radius_km) }

  # 円内座標（中心から約1km）
  let(:in_circle_lat) { 35.6770 }
  let(:in_circle_lng) { 139.6510 }

  # 円外座標（中心から約100km）
  let(:out_circle_lat) { 36.5 }
  let(:out_circle_lng) { 140.5 }

  describe "#fetch_for_slots" do
    context "基本動作" do
      let!(:genre_food) { create(:genre, name: "グルメ", slug: "food", visible: true) }
      let!(:genre_bath) { create(:genre, name: "温泉", slug: "bath", visible: true) }

      let!(:food_spot) do
        create(:spot, lat: in_circle_lat, lng: in_circle_lng).tap { |s| s.genres << genre_food }
      end

      let!(:bath_spot) do
        create(:spot, lat: in_circle_lat + 0.001, lng: in_circle_lng).tap { |s| s.genres << genre_bath }
      end

      it "指定ジャンルのスロット候補を返す" do
        slots = [ { genre_id: genre_food.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("グルメ")
        expect(result.first[:candidates].map { |c| c[:id] }).to include(food_spot.id)
      end

      it "複数スロットに対応する" do
        slots = [ { genre_id: genre_food.id }, { genre_id: genre_bath.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.length).to eq(2)
        expect(result.map { |r| r[:genre_name] }).to contain_exactly("グルメ", "温泉")
      end

      it "円外のスポットは含まない" do
        create(:spot, lat: out_circle_lat, lng: out_circle_lng).tap { |s| s.genres << genre_food }

        slots = [ { genre_id: genre_food.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result.first[:candidates].length).to eq(1)
        expect(result.first[:candidates].first[:id]).to eq(food_spot.id)
      end
    end

    context "優先ジャンルキュー" do
      let!(:genre_sightseeing) { create(:genre, name: "観光", slug: "sightseeing", visible: true) }
      let!(:genre_food) { create(:genre, name: "グルメ", slug: "food", visible: true) }

      let!(:sightseeing_spot) do
        create(:spot, lat: in_circle_lat, lng: in_circle_lng).tap { |s| s.genres << genre_sightseeing }
      end

      let!(:food_spot) do
        create(:spot, lat: in_circle_lat + 0.001, lng: in_circle_lng).tap { |s| s.genres << genre_food }
      end

      it "空スロット（genre_id: nil）はキューの先頭ジャンルを使う" do
        slots = [ { genre_id: nil } ]
        priority_genre_ids = [ genre_sightseeing.id, genre_food.id ]

        result = finder.fetch_for_slots(slots, priority_genre_ids: priority_genre_ids)

        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("観光")
      end

      it "キューは順番に消費される" do
        slots = [ { genre_id: nil }, { genre_id: nil } ]
        priority_genre_ids = [ genre_sightseeing.id, genre_food.id ]

        result = finder.fetch_for_slots(slots, priority_genre_ids: priority_genre_ids)

        expect(result.length).to eq(2)
        expect(result[0][:genre_name]).to eq("観光")
        expect(result[1][:genre_name]).to eq("グルメ")
      end

      it "ユーザー選択済みジャンルはキューから除外される" do
        slots = [ { genre_id: genre_sightseeing.id }, { genre_id: nil } ]
        priority_genre_ids = [ genre_sightseeing.id, genre_food.id ]

        result = finder.fetch_for_slots(slots, priority_genre_ids: priority_genre_ids)

        expect(result.length).to eq(2)
        expect(result[0][:genre_name]).to eq("観光")
        expect(result[1][:genre_name]).to eq("グルメ")  # sightseeingはスキップされfoodが使われる
      end
    end

    context "nilフォールバック（お任せ）" do
      let!(:genre_food) { create(:genre, name: "グルメ", slug: "food", visible: true, category: "食べる") }
      let!(:genre_bath) { create(:genre, name: "温泉", slug: "bath", visible: true, category: "温まる") }

      let!(:food_spot) do
        create(:spot, lat: in_circle_lat, lng: in_circle_lng).tap { |s| s.genres << genre_food }
      end

      it "キューが空の場合はお任せ（全ジャンル）にフォールバックする" do
        slots = [ { genre_id: nil } ]

        result = finder.fetch_for_slots(slots, priority_genre_ids: [])

        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("おすすめ")
        expect(result.first[:candidates].map { |c| c[:id] }).to include(food_spot.id)
      end

      it "キューのジャンルに該当スポットがない場合もフォールバックする" do
        slots = [ { genre_id: nil } ]
        priority_genre_ids = [ genre_bath.id ]  # 温泉スポットは存在しない

        result = finder.fetch_for_slots(slots, priority_genre_ids: priority_genre_ids)

        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("おすすめ")
      end

      it "「その他」カテゴリのスポットは除外される" do
        genre_other = create(:genre, name: "駐車場", slug: "parking", visible: true, category: "その他")
        create(:spot, lat: in_circle_lat + 0.002, lng: in_circle_lng).tap { |s| s.genres << genre_other }

        slots = [ { genre_id: nil } ]
        result = finder.fetch_for_slots(slots, priority_genre_ids: [])

        # 「その他」カテゴリのスポットは含まれず、グルメスポットのみ
        expect(result.first[:candidates].map { |c| c[:id] }).not_to include(Spot.last.id)
        expect(result.first[:candidates].map { |c| c[:id] }).to include(food_spot.id)
      end

      it "「泊まる」カテゴリのスポットは除外される" do
        genre_stay = create(:genre, name: "宿泊施設", slug: "accommodation", visible: true, category: "泊まる")
        stay_spot = create(:spot, lat: in_circle_lat + 0.003, lng: in_circle_lng).tap { |s| s.genres << genre_stay }

        slots = [ { genre_id: nil } ]
        result = finder.fetch_for_slots(slots, priority_genre_ids: [])

        # 「泊まる」カテゴリのスポットは含まれない
        expect(result.first[:candidates].map { |c| c[:id] }).not_to include(stay_spot.id)
        expect(result.first[:candidates].map { |c| c[:id] }).to include(food_spot.id)
      end
    end

    context "ジャンル重複防止" do
      let!(:genre_food) { create(:genre, name: "グルメ", slug: "food", visible: true, category: "食べる") }

      let!(:food_spot1) do
        create(:spot, name: "ラーメン屋A", lat: in_circle_lat, lng: in_circle_lng).tap { |s| s.genres << genre_food }
      end

      let!(:food_spot2) do
        create(:spot, name: "ラーメン屋B", lat: in_circle_lat + 0.001, lng: in_circle_lng).tap { |s| s.genres << genre_food }
      end

      it "同じ主要ジャンルのスポットは2回目以降のスロットで除外される" do
        slots = [ { genre_id: nil }, { genre_id: nil } ]

        result = finder.fetch_for_slots(slots, priority_genre_ids: [])

        # 最初のスロットでグルメが使われたので、2つ目のスロットは空
        expect(result.length).to eq(1)
        expect(result.first[:genre_name]).to eq("おすすめ")
      end

      context "複数ジャンルを持つスポット" do
        let!(:genre_sightseeing) { create(:genre, name: "観光", slug: "sightseeing", visible: true, category: "見る") }

        let!(:multi_genre_spot) do
          create(:spot, name: "観光グルメスポット", lat: in_circle_lat + 0.002, lng: in_circle_lng).tap do |s|
            s.genres << genre_sightseeing
            s.genres << genre_food
          end
        end

        it "主要ジャンル（最初のジャンル）で重複判定される" do
          slots = [ { genre_id: genre_sightseeing.id }, { genre_id: nil } ]

          result = finder.fetch_for_slots(slots, priority_genre_ids: [])

          # 観光スポットが使われた後、同じ「観光」主要ジャンルのスポットは除外
          # グルメスポットは残る
          expect(result.length).to eq(2)
          expect(result[0][:genre_name]).to eq("観光")
          expect(result[1][:genre_name]).to eq("おすすめ")
          expect(result[1][:candidates].map { |c| c[:id] }).to include(food_spot1.id)
        end
      end
    end

    context "スポット重複防止" do
      let!(:genre_food) { create(:genre, name: "グルメ", slug: "food", visible: true) }
      let!(:genre_sightseeing) { create(:genre, name: "観光", slug: "sightseeing", visible: true) }

      let!(:multi_genre_spot) do
        create(:spot, lat: in_circle_lat, lng: in_circle_lng).tap do |s|
          s.genres << genre_food
          s.genres << genre_sightseeing
        end
      end

      it "同じスポットは複数スロットに含まれない" do
        slots = [ { genre_id: genre_food.id }, { genre_id: genre_sightseeing.id } ]

        result = finder.fetch_for_slots(slots)

        # 最初のスロットでスポットが使われ、2つ目は空
        expect(result.length).to eq(1)
      end
    end

    context "該当スポットがない場合" do
      let!(:genre) { create(:genre, name: "存在しない", slug: "nonexistent", visible: true) }

      it "そのスロットをスキップする" do
        slots = [ { genre_id: genre.id } ]
        result = finder.fetch_for_slots(slots)

        expect(result).to be_empty
      end
    end
  end
end
