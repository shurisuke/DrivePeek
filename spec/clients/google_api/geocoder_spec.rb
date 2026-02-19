# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleApi::Geocoder do
  # rails_helper.rbのグローバルスタブを無効化して実際のメソッドをテスト
  before do
    allow(GoogleApi::Geocoder).to receive(:reverse).and_call_original
    allow(GoogleApi::Geocoder).to receive(:forward).and_call_original
  end

  describe ".forward" do
    let(:api_url) { "https://maps.googleapis.com/maps/api/geocode/json" }

    context "住所が空の場合" do
      it "nilを返す" do
        expect(GoogleApi::Geocoder.forward("")).to be_nil
        expect(GoogleApi::Geocoder.forward(nil)).to be_nil
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            results: [ {
              geometry: { location: { lat: 35.6812, lng: 139.7671 } },
              address_components: [
                { long_name: "東京都", types: [ "administrative_area_level_1" ] }
              ]
            } ]
          }.to_json)
      end

      it "緯度経度と都道府県を返す" do
        result = GoogleApi::Geocoder.forward("東京都千代田区")

        expect(result).to eq({
          lat: 35.6812,
          lng: 139.7671,
          prefecture: "東京都"
        })
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS" }.to_json)
      end

      it "nilを返す" do
        expect(GoogleApi::Geocoder.forward("存在しない住所")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_raise(StandardError.new("connection error"))
      end

      it "nilを返す" do
        expect(GoogleApi::Geocoder.forward("東京都")).to be_nil
      end
    end
  end

  describe ".reverse" do
    context "緯度経度が空の場合" do
      it "nilを返す" do
        result = GoogleApi::Geocoder.reverse(lat: nil, lng: nil)

        expect(result).to be_nil
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            results: [ {
              formatted_address: "日本、〒329-1117 栃木県宇都宮市叶谷町４７−１１１",
              address_components: [
                { long_name: "栃木県", types: [ "administrative_area_level_1" ] },
                { long_name: "宇都宮市", types: [ "locality" ] },
                { long_name: "叶谷町", types: [ "sublocality_level_2" ] }
              ]
            } ]
          }.to_json)
      end

      it "正規化された住所情報を返す" do
        result = GoogleApi::Geocoder.reverse(lat: 36.5, lng: 139.8)

        expect(result[:address]).to eq("栃木県宇都宮市叶谷町４７−１１１")
        expect(result[:prefecture]).to eq("栃木県")
        expect(result[:city]).to eq("宇都宮市")
        expect(result[:town]).to eq("叶谷町")
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS" }.to_json)
      end

      it "nilを返す" do
        result = GoogleApi::Geocoder.reverse(lat: 0.001, lng: 0.001)

        expect(result).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_raise(StandardError.new("timeout"))
      end

      it "nilを返す" do
        result = GoogleApi::Geocoder.reverse(lat: 35.1, lng: 139.1)

        expect(result).to be_nil
      end
    end
  end
end
