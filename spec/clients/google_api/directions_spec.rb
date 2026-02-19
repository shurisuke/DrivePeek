# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleApi::Directions do
  describe ".fetch" do
    let(:origin) { { lat: 35.6812, lng: 139.7671 } }
    let(:destination) { { lat: 35.7100, lng: 139.8107 } }

    context "座標が空の場合" do
      it "originが空ならnilを返す" do
        expect(GoogleApi::Directions.fetch(origin: { lat: nil, lng: nil }, destination: destination)).to be_nil
      end

      it "destinationが空ならnilを返す" do
        expect(GoogleApi::Directions.fetch(origin: origin, destination: { lat: nil, lng: nil })).to be_nil
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/directions\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            routes: [ {
              legs: [ {
                duration: { value: 1800, text: "30分" },
                distance: { value: 15000, text: "15 km" }
              } ],
              overview_polyline: { points: "abc123xyz" }
            } ]
          }.to_json)
      end

      it "移動時間・距離・ポリラインを返す" do
        result = GoogleApi::Directions.fetch(origin: origin, destination: destination)

        expect(result[:move_time]).to eq(30)
        expect(result[:move_distance]).to eq(15.0)
        expect(result[:polyline]).to eq("abc123xyz")
      end

      it "toll_used=falseの場合、avoid=tollsパラメータを送信する" do
        GoogleApi::Directions.fetch(origin: origin, destination: destination, toll_used: false)

        expect(WebMock).to have_requested(:get, /maps.googleapis.com/)
          .with(query: hash_including(avoid: "tolls"))
      end

      it "toll_used=trueの場合、avoidパラメータを送信しない" do
        GoogleApi::Directions.fetch(origin: origin, destination: destination, toll_used: true)

        expect(WebMock).to have_requested(:get, /maps.googleapis.com/)
          .with { |req| !req.uri.query.include?("avoid=") }
      end
    end

    context "移動時間の端数処理" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/directions\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            routes: [ {
              legs: [ {
                duration: { value: 125, text: "2分" },
                distance: { value: 500, text: "0.5 km" }
              } ],
              overview_polyline: { points: "test" }
            } ]
          }.to_json)
      end

      it "秒を分に変換し、切り上げる" do
        result = GoogleApi::Directions.fetch(origin: origin, destination: destination)

        expect(result[:move_time]).to eq(3) # 125秒 = 2.08分 → 切り上げて3分
        expect(result[:move_distance]).to eq(0.5)
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/directions\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS" }.to_json)
      end

      it "nilを返す" do
        expect(GoogleApi::Directions.fetch(origin: origin, destination: destination)).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/directions\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(GoogleApi::Directions.fetch(origin: origin, destination: destination)).to be_nil
      end
    end
  end
end
