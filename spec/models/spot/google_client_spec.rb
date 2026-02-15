# frozen_string_literal: true

require "rails_helper"

RSpec.describe Spot::GoogleClient do
  describe ".find_by_name" do
    context "名前が空の場合" do
      it "nilを返す" do
        expect(Spot::GoogleClient.find_by_name("")).to be_nil
        expect(Spot::GoogleClient.find_by_name(nil)).to be_nil
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            candidates: [ {
              place_id: "ChIJ12345",
              name: "東京タワー",
              geometry: { location: { lat: 35.6586, lng: 139.7454 } }
            } ]
          }.to_json)
      end

      it "place_id、名前、緯度経度を返す" do
        result = Spot::GoogleClient.find_by_name("東京タワー")

        expect(result).to eq({
          place_id: "ChIJ12345",
          name: "東京タワー",
          lat: 35.6586,
          lng: 139.7454
        })
      end
    end

    context "位置バイアスを指定した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .with(query: hash_including(locationbias: "point:35.0,139.0"))
          .to_return(status: 200, body: {
            status: "OK",
            candidates: [ {
              place_id: "ChIJ99999",
              name: "近くのスポット",
              geometry: { location: { lat: 35.01, lng: 139.01 } }
            } ]
          }.to_json)
      end

      it "位置バイアス付きでリクエストする" do
        result = Spot::GoogleClient.find_by_name("テスト", lat: 35.0, lng: 139.0)

        expect(result[:place_id]).to eq("ChIJ99999")
      end
    end

    context "候補が見つからない場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS", candidates: [] }.to_json)
      end

      it "nilを返す" do
        expect(Spot::GoogleClient.find_by_name("存在しないスポット")).to be_nil
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "REQUEST_DENIED" }.to_json)
      end

      it "nilを返す" do
        expect(Spot::GoogleClient.find_by_name("テスト")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(Spot::GoogleClient.find_by_name("テスト")).to be_nil
      end
    end

    context "geometryがない候補の場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            candidates: [ {
              place_id: "ChIJ00000",
              name: "ジオメトリなし"
            } ]
          }.to_json)
      end

      it "lat/lngがnilのハッシュを返す" do
        result = Spot::GoogleClient.find_by_name("テスト")

        expect(result[:place_id]).to eq("ChIJ00000")
        expect(result[:lat]).to be_nil
        expect(result[:lng]).to be_nil
      end
    end
  end

  describe ".fetch_details" do
    context "place_idが空の場合" do
      it "nilを返す" do
        expect(Spot::GoogleClient.fetch_details("")).to be_nil
        expect(Spot::GoogleClient.fetch_details(nil)).to be_nil
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            result: {
              name: "東京タワー",
              formatted_address: "日本、〒105-0011 東京都港区芝公園４丁目２−８",
              photos: [
                { photo_reference: "ref123" },
                { photo_reference: "ref456" }
              ]
            }
          }.to_json)
      end

      it "name、address、photo_urlsを返す" do
        result = Spot::GoogleClient.fetch_details("ChIJ12345")

        expect(result[:name]).to eq("東京タワー")
        expect(result[:address]).to eq("東京都港区芝公園４丁目２−８")
        expect(result[:photo_urls]).to be_an(Array)
        expect(result[:photo_urls].length).to eq(2)
      end

      it "住所を正規化する（日本、郵便番号を除去）" do
        result = Spot::GoogleClient.fetch_details("ChIJ12345")

        expect(result[:address]).not_to include("日本")
        expect(result[:address]).not_to include("〒")
      end
    end

    context "写真なしでリクエストした場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .with(query: hash_excluding("photos"))
          .to_return(status: 200, body: {
            status: "OK",
            result: {
              name: "テストスポット",
              formatted_address: "東京都渋谷区"
            }
          }.to_json)
      end

      it "photo_urlsは空配列" do
        result = Spot::GoogleClient.fetch_details("ChIJ12345", include_photos: false)

        expect(result[:photo_urls]).to eq([])
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_return(status: 200, body: { status: "INVALID_REQUEST" }.to_json)
      end

      it "nilを返す" do
        expect(Spot::GoogleClient.fetch_details("invalid_id")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(Spot::GoogleClient.fetch_details("ChIJ12345")).to be_nil
      end
    end
  end
end
