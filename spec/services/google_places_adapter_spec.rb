# frozen_string_literal: true

require "rails_helper"

RSpec.describe GooglePlacesAdapter do
  describe ".find_place" do
    let(:api_url) { "https://maps.googleapis.com/maps/api/place/findplacefromtext/json" }

    context "名前が空の場合" do
      it "nilを返す" do
        expect(GooglePlacesAdapter.find_place(name: "")).to be_nil
        expect(GooglePlacesAdapter.find_place(name: nil)).to be_nil
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
        result = GooglePlacesAdapter.find_place(name: "東京タワー")

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
        result = GooglePlacesAdapter.find_place(name: "テスト", lat: 35.0, lng: 139.0)

        expect(result[:place_id]).to eq("ChIJ99999")
      end
    end

    context "候補が見つからない場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS", candidates: [] }.to_json)
      end

      it "nilを返す" do
        expect(GooglePlacesAdapter.find_place(name: "存在しないスポット")).to be_nil
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "REQUEST_DENIED" }.to_json)
      end

      it "nilを返す" do
        expect(GooglePlacesAdapter.find_place(name: "テスト")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(GooglePlacesAdapter.find_place(name: "テスト")).to be_nil
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
        result = GooglePlacesAdapter.find_place(name: "テスト")

        expect(result[:place_id]).to eq("ChIJ00000")
        expect(result[:lat]).to be_nil
        expect(result[:lng]).to be_nil
      end
    end
  end
end
