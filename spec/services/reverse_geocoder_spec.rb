# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReverseGeocoder do
  # rails_helper.rbのグローバルスタブを無効化して実際のメソッドをテスト
  before do
    allow(ReverseGeocoder).to receive(:lookup_address).and_call_original
    allow(ReverseGeocoder).to receive(:geocode_address).and_call_original
  end
  describe ".geocode_address" do
    let(:api_url) { "https://maps.googleapis.com/maps/api/geocode/json" }

    context "住所が空の場合" do
      it "nilを返す" do
        expect(ReverseGeocoder.geocode_address("")).to be_nil
        expect(ReverseGeocoder.geocode_address(nil)).to be_nil
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
        result = ReverseGeocoder.geocode_address("東京都千代田区")

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
        expect(ReverseGeocoder.geocode_address("存在しない住所")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_raise(StandardError.new("connection error"))
      end

      it "nilを返す" do
        expect(ReverseGeocoder.geocode_address("東京都")).to be_nil
      end
    end
  end

  describe ".lookup_address" do
    context "緯度経度が空の場合" do
      it "フォールバックロケーションを返す" do
        result = ReverseGeocoder.lookup_address(lat: nil, lng: nil)

        expect(result).to eq(ReverseGeocoder::FALLBACK_LOCATION)
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
        result = ReverseGeocoder.lookup_address(lat: 36.5, lng: 139.8)

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

      it "フォールバックロケーションを返す" do
        result = ReverseGeocoder.lookup_address(lat: 0.001, lng: 0.001)

        expect(result).to eq(ReverseGeocoder::FALLBACK_LOCATION)
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/geocode\/json/)
          .to_raise(StandardError.new("timeout"))
      end

      it "フォールバックロケーションを返す" do
        result = ReverseGeocoder.lookup_address(lat: 35.1, lng: 139.1)

        expect(result).to eq(ReverseGeocoder::FALLBACK_LOCATION)
      end
    end
  end

  describe ".normalize_address" do
    it "国名を削除する" do
      expect(ReverseGeocoder.normalize_address("日本、東京都")).to eq("東京都")
    end

    it "郵便番号を削除する" do
      expect(ReverseGeocoder.normalize_address("〒100-0001 東京都千代田区")).to eq("東京都千代田区")
    end

    it "国名と郵便番号を両方削除する" do
      expect(ReverseGeocoder.normalize_address("日本、〒100-0001 東京都千代田区")).to eq("東京都千代田区")
    end

    it "全角ハイフンの郵便番号も処理する" do
      expect(ReverseGeocoder.normalize_address("〒329−1117 栃木県")).to eq("栃木県")
    end
  end
end
