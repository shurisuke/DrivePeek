# frozen_string_literal: true

require "rails_helper"

RSpec.describe Suggestion::Generator do
  let(:plan) { create(:plan) }
  let(:center_lat) { 35.6762 }
  let(:center_lng) { 139.6503 }
  let(:radius_km) { 10.0 }

  describe ".generate" do
    context "API未設定の場合" do
      before { allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil) }

      it "エラーレスポンスを返す" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km
        )

        expect(result[:type]).to eq("error")
        expect(result[:message]).to include("API設定エラー")
        expect(result[:spots]).to eq([])
      end
    end

    context "プランモード" do
      let!(:genre) { create(:genre, name: "ごはん", slug: "food") }
      let!(:spot) do
        create(:spot, lat: 35.6770, lng: 139.6510, name: "テストスポット").tap do |s|
          s.genres << genre
        end
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "おすすめの理由です" } ],
          intro: "素敵なエリアです",
          closing: "楽しんでください"
        }.to_json)
      end

      it "提案を生成する" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre.id } ]
        )

        expect(result[:type]).to eq("plan")
        expect(result[:intro]).to eq("素敵なエリアです")
        expect(result[:spots]).not_to be_empty
        expect(result[:closing]).to eq("楽しんでください")
      end

      it "スポット情報を含める" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre.id } ]
        )

        spot_result = result[:spots].first
        expect(spot_result[:spot_id]).to eq(spot.id)
        expect(spot_result[:name]).to eq("テストスポット")
        expect(spot_result[:description]).to eq("おすすめの理由です")
      end
    end

    context "該当スポットがない場合" do
      let!(:genre) { create(:genre, name: "温泉", slug: "bath") }

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
      end

      it "適切なメッセージを返す" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre.id } ]
        )

        expect(result[:message]).to include("スポットが見つかりませんでした")
        expect(result[:spots]).to eq([])
      end
    end

    context "API通信エラーの場合" do
      let!(:genre) { create(:genre, name: "ごはん", slug: "food") }
      let!(:spot) do
        create(:spot, lat: 35.6770, lng: 139.6510).tap { |s| s.genres << genre }
      end

      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        stub_openai_error(status: 500)
      end

      it "エラーレスポンスを返す" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre.id } ]
        )

        expect(result[:message]).to include("通信エラー")
        expect(result[:spots]).to eq([])
      end
    end

    context "フォールバック動作" do
      let!(:genre1) { create(:genre, name: "ごはん", slug: "food") }
      let!(:genre2) { create(:genre, name: "温泉", slug: "bath") }
      let!(:spot1) { create(:spot, lat: 35.6770, lng: 139.6510, name: "グルメスポット") }
      let!(:spot2) { create(:spot, lat: 35.6780, lng: 139.6520, name: "温泉スポット") }

      before do
        spot1.genres << genre1
        spot2.genres << genre2

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        # AIが空のpicksを返す場合
        stub_openai_chat(response_content: {
          picks: [],
          intro: "紹介文",
          closing: "締めの文"
        }.to_json)
      end

      it "各スロットの人気1位をフォールバックとして採用する" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id } ]
        )

        expect(result[:spots].length).to eq(2)
        spot_names = result[:spots].map { |s| s[:name] }
        expect(spot_names).to include("グルメスポット", "温泉スポット")
      end
    end

    context "スロット数に応じた提案数" do
      let!(:genre1) { create(:genre, name: "観光名所", slug: "sightseeing") }
      let!(:genre2) { create(:genre, name: "ごはん", slug: "food") }
      let!(:genre3) { create(:genre, name: "道の駅", slug: "roadside_station") }
      let!(:genre4) { create(:genre, name: "温泉", slug: "bath") }
      let!(:spot1) { create(:spot, lat: 35.6770, lng: 139.6510, name: "観光スポット") }
      let!(:spot2) { create(:spot, lat: 35.6771, lng: 139.6511, name: "グルメスポット") }
      let!(:spot3) { create(:spot, lat: 35.6772, lng: 139.6512, name: "道の駅スポット") }
      let!(:spot4) { create(:spot, lat: 35.6773, lng: 139.6513, name: "温泉スポット") }

      before do
        spot1.genres << genre1
        spot2.genres << genre2
        spot3.genres << genre3
        spot4.genres << genre4

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
      end

      it "2スロット指定で2件提案される" do
        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "説明1" }, { n: 2, d: "説明2" } ],
          intro: "紹介文",
          closing: "締めの文"
        }.to_json)

        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id } ]
        )

        expect(result[:spots].length).to eq(2)
      end

      it "3スロット指定で3件提案される" do
        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "説明1" }, { n: 2, d: "説明2" }, { n: 3, d: "説明3" } ],
          intro: "紹介文",
          closing: "締めの文"
        }.to_json)

        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id }, { genre_id: genre3.id } ]
        )

        expect(result[:spots].length).to eq(3)
      end

      it "4スロット指定で4件提案される" do
        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "説明1" }, { n: 2, d: "説明2" }, { n: 3, d: "説明3" }, { n: 4, d: "説明4" } ],
          intro: "紹介文",
          closing: "締めの文"
        }.to_json)

        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id }, { genre_id: genre3.id }, { genre_id: genre4.id } ]
        )

        expect(result[:spots].length).to eq(4)
      end

      it "AIが不足件数を返した場合フォールバックで補完される" do
        # 3スロット指定だがAIは2件しか返さない
        stub_openai_chat(response_content: {
          picks: [ { n: 1, d: "説明1" }, { n: 2, d: "説明2" } ],
          intro: "紹介文",
          closing: "締めの文"
        }.to_json)

        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id }, { genre_id: genre3.id } ]
        )

        expect(result[:spots].length).to eq(3)
        spot_names = result[:spots].map { |s| s[:name] }
        expect(spot_names).to include("道の駅スポット")
      end
    end
  end
end
