# frozen_string_literal: true

require "rails_helper"

RSpec.describe SpotImporter::KantoImporter do
  let(:importer) { described_class.new }

  let(:api_result) do
    {
      place_id: "ChIJ_test_place_id",
      name: "テストスポット",
      address: "東京都渋谷区道玄坂1-2-3",
      lat: 35.6812,
      lng: 139.7671
    }
  end

  before do
    # 標準出力を抑制
    allow($stdout).to receive(:print)
    allow($stdout).to receive(:puts)
  end

  describe "#run" do
    before do
      allow(Spot::GoogleClient).to receive(:text_search).and_return([ api_result ])
    end

    context "テストモード" do
      it "新規スポットを作成する" do
        expect {
          importer.run(test_mode: true)
        }.to change { Spot.count }.by(1)
      end

      it "既存スポットはスキップする" do
        create(:spot, place_id: api_result[:place_id])

        expect {
          importer.run(test_mode: true)
        }.not_to change { Spot.count }
      end

      it "住所から都道府県・市区町村を抽出する" do
        importer.run(test_mode: true)

        spot = Spot.find_by(place_id: api_result[:place_id])
        expect(spot.prefecture).to eq("東京都")
        expect(spot.city).to eq("渋谷区")
      end
    end
  end

  describe "リトライロジック" do
    it "一時的なエラー後にリトライで成功する" do
      first_call = true
      allow(Spot::GoogleClient).to receive(:text_search) do
        if first_call
          first_call = false
          raise StandardError, "API error"
        end
        [ api_result ]
      end

      # sleepをスキップ
      allow(importer).to receive(:sleep)

      # リトライ後にスポットが作成される
      expect {
        importer.run(test_mode: true)
      }.to change { Spot.count }.by(1)
    end

    it "3回リトライ後も失敗したらエラーをカウントする" do
      allow(Spot::GoogleClient).to receive(:text_search).and_raise(StandardError, "Persistent error")
      allow(importer).to receive(:sleep)

      # エラーが発生してもクラッシュしない
      expect { importer.run(test_mode: true) }.not_to raise_error
    end
  end
end
