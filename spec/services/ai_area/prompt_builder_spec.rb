# frozen_string_literal: true

require "rails_helper"

RSpec.describe AiArea::PromptBuilder, type: :service do
  describe ".plan_mode" do
    let(:slot_data) do
      [
        {
          genre_name: "グルメ",
          candidates: [
            { id: 1, name: "ラーメン屋", city: "渋谷区" },
            { id: 2, name: "寿司屋", city: "渋谷区" }
          ]
        },
        {
          genre_name: "温泉",
          candidates: [
            { id: 3, name: "温泉旅館", city: "渋谷区" }
          ]
        }
      ]
    end
    let(:radius_km) { 10.5 }

    it "プロンプトを生成する" do
      prompt = described_class.plan_mode(slot_data, radius_km)

      expect(prompt).to include("ドライブプランAI")
      expect(prompt).to include("半径10.5km")
      expect(prompt).to include("渋谷区周辺")
    end

    it "候補スポットを通し番号で含める" do
      prompt = described_class.plan_mode(slot_data, radius_km)

      expect(prompt).to include("[グルメ]")
      expect(prompt).to include("1.ラーメン屋")
      expect(prompt).to include("2.寿司屋")
      expect(prompt).to include("[温泉]")
      expect(prompt).to include("3.温泉旅館")
    end

    it "JSON形式の指示を含める" do
      prompt = described_class.plan_mode(slot_data, radius_km)

      expect(prompt).to include("JSON")
      expect(prompt).to include("picks")
      expect(prompt).to include("intro")
      expect(prompt).to include("closing")
    end

    context "季節ガイド" do
      it "現在の月に応じた季節情報を含める" do
        allow(Time).to receive(:current).and_return(Time.zone.local(2024, 1, 15))

        prompt = described_class.plan_mode(slot_data, radius_km)

        expect(prompt).to include("1月")
        expect(prompt).to include("冬")
      end

      it "夏は夏向けのガイドを含める" do
        allow(Time).to receive(:current).and_return(Time.zone.local(2024, 7, 15))

        prompt = described_class.plan_mode(slot_data, radius_km)

        expect(prompt).to include("7月")
        expect(prompt).to include("夏")
      end
    end

    context "候補が空の場合" do
      let(:empty_slot_data) { [] }

      it "エリア名をデフォルトにする" do
        prompt = described_class.plan_mode(empty_slot_data, radius_km)

        expect(prompt).to include("選択エリア周辺")
      end
    end
  end

  describe ".spot_mode" do
    let(:candidates) do
      [
        { id: 1, name: "ラーメン一郎", city: "新宿区" },
        { id: 2, name: "ラーメン二郎", city: "新宿区" },
        { id: 3, name: "ラーメン三郎", city: "新宿区" }
      ]
    end
    let(:genre) { create(:genre, name: "ラーメン") }
    let(:radius_km) { 15.0 }

    it "プロンプトを生成する" do
      prompt = described_class.spot_mode(candidates, genre, radius_km)

      expect(prompt).to include("ドライブスポット紹介AI")
      expect(prompt).to include("半径15.0km")
      expect(prompt).to include("新宿区周辺")
    end

    it "ジャンル名を含める" do
      prompt = described_class.spot_mode(candidates, genre, radius_km)

      expect(prompt).to include("ジャンル: ラーメン")
    end

    it "人気スポット一覧を含める" do
      prompt = described_class.spot_mode(candidates, genre, radius_km)

      expect(prompt).to include("ラーメン一郎")
      expect(prompt).to include("ラーメン二郎")
      expect(prompt).to include("ラーメン三郎")
    end

    it "JSON形式の指示を含める" do
      prompt = described_class.spot_mode(candidates, genre, radius_km)

      expect(prompt).to include("JSON")
      expect(prompt).to include("intro")
      expect(prompt).to include("closing")
    end

    context "候補が空の場合" do
      let(:empty_candidates) { [] }

      it "エリア名をデフォルトにする" do
        prompt = described_class.spot_mode(empty_candidates, genre, radius_km)

        expect(prompt).to include("選択エリア周辺")
      end
    end
  end

  describe "SEASON_GUIDE" do
    it "12ヶ月分の季節ガイドを持つ" do
      expect(described_class::SEASON_GUIDE.keys).to contain_exactly(*(1..12))
    end

    it "各月にガイド文がある" do
      described_class::SEASON_GUIDE.each do |month, guide|
        expect(guide).to be_present, "#{month}月のガイドが空です"
      end
    end
  end
end
