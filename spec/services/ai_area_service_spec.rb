# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiAreaService, type: :service do
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

        expect(result[:type]).to eq("plan")
        expect(result[:message]).to include("API設定エラー")
        expect(result[:spots]).to eq([])
      end
    end

    context "プランモード" do
      let!(:genre) { create(:genre, name: "グルメ", slug: "gourmet") }
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
          slots: [ { genre_id: genre.id } ],
          mode: "plan"
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
          slots: [ { genre_id: genre.id } ],
          mode: "plan"
        )

        spot_result = result[:spots].first
        expect(spot_result[:spot_id]).to eq(spot.id)
        expect(spot_result[:name]).to eq("テストスポット")
        expect(spot_result[:description]).to eq("おすすめの理由です")
      end
    end

    context "スポットモード" do
      let!(:genre) { create(:genre, name: "ラーメン", slug: "ramen") }
      let!(:spot1) { create(:spot, lat: 35.6770, lng: 139.6510, name: "ラーメン屋1") }
      let!(:spot2) { create(:spot, lat: 35.6780, lng: 139.6520, name: "ラーメン屋2") }

      before do
        spot1.genres << genre
        spot2.genres << genre

        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        stub_openai_chat(response_content: {
          intro: "人気のラーメン店です",
          closing: "ぜひ追加してください"
        }.to_json)
      end

      it "提案を生成する" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          mode: "spots",
          genre_id: genre.id,
          count: 2
        )

        expect(result[:type]).to eq("spots")
        expect(result[:intro]).to eq("人気のラーメン店です")
        expect(result[:spots].length).to eq(2)
      end

      it "ジャンルが見つからない場合エラーを返す" do
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          mode: "spots",
          genre_id: 99999,
          count: 5
        )

        expect(result[:message]).to include("ジャンルが見つかりません")
      end
    end

    context "該当スポットがない場合" do
      let!(:genre) { create(:genre, name: "温泉", slug: "onsen") }

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
          slots: [ { genre_id: genre.id } ],
          mode: "plan"
        )

        expect(result[:message]).to include("スポットが見つかりませんでした")
        expect(result[:spots]).to eq([])
      end
    end

    context "不正なモードの場合" do
      before do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")
      end

      it "エラーを返す" do
        result = described_class.generate(
          plan: plan,
          center_lat: center_lat,
          center_lng: center_lng,
          radius_km: radius_km,
          mode: "invalid"
        )

        expect(result[:message]).to include("不正なモード")
      end
    end

    context "API通信エラーの場合" do
      let!(:genre) { create(:genre, name: "グルメ", slug: "gourmet") }
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
          slots: [ { genre_id: genre.id } ],
          mode: "plan"
        )

        expect(result[:message]).to include("通信エラー")
        expect(result[:spots]).to eq([])
      end
    end

    context "フォールバック動作" do
      let!(:genre1) { create(:genre, name: "グルメ", slug: "gourmet") }
      let!(:genre2) { create(:genre, name: "温泉", slug: "onsen") }
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
          slots: [ { genre_id: genre1.id }, { genre_id: genre2.id } ],
          mode: "plan"
        )

        expect(result[:spots].length).to eq(2)
        spot_names = result[:spots].map { |s| s[:name] }
        expect(spot_names).to include("グルメスポット", "温泉スポット")
      end
    end
  end
end
