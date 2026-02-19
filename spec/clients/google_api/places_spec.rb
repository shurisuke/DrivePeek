# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleApi::Places do
  describe ".find_by_name" do
    context "名前が空の場合" do
      it "nilを返す" do
        expect(GoogleApi::Places.find_by_name("")).to be_nil
        expect(GoogleApi::Places.find_by_name(nil)).to be_nil
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
        result = GoogleApi::Places.find_by_name("東京タワー")

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
        result = GoogleApi::Places.find_by_name("テスト", lat: 35.0, lng: 139.0)

        expect(result[:place_id]).to eq("ChIJ99999")
      end
    end

    context "候補が見つからない場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS", candidates: [] }.to_json)
      end

      it "nilを返す" do
        expect(GoogleApi::Places.find_by_name("存在しないスポット")).to be_nil
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_return(status: 200, body: { status: "REQUEST_DENIED" }.to_json)
      end

      it "nilを返す" do
        expect(GoogleApi::Places.find_by_name("テスト")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/findplacefromtext\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(GoogleApi::Places.find_by_name("テスト")).to be_nil
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
        result = GoogleApi::Places.find_by_name("テスト")

        expect(result[:place_id]).to eq("ChIJ00000")
        expect(result[:lat]).to be_nil
        expect(result[:lng]).to be_nil
      end
    end
  end

  describe ".fetch_details" do
    context "place_idが空の場合" do
      it "nilを返す" do
        expect(GoogleApi::Places.fetch_details("")).to be_nil
        expect(GoogleApi::Places.fetch_details(nil)).to be_nil
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
        result = GoogleApi::Places.fetch_details("ChIJ12345")

        expect(result[:name]).to eq("東京タワー")
        expect(result[:address]).to eq("東京都港区芝公園４丁目２−８")
        expect(result[:photo_urls]).to be_an(Array)
        expect(result[:photo_urls].length).to eq(2)
      end

      it "住所を正規化する（日本、郵便番号を除去）" do
        result = GoogleApi::Places.fetch_details("ChIJ12345")

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
        result = GoogleApi::Places.fetch_details("ChIJ12345", include_photos: false)

        expect(result[:photo_urls]).to eq([])
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_return(status: 200, body: { status: "INVALID_REQUEST" }.to_json)
      end

      it "nilを返す" do
        expect(GoogleApi::Places.fetch_details("invalid_id")).to be_nil
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "nilを返す" do
        expect(GoogleApi::Places.fetch_details("ChIJ12345")).to be_nil
      end
    end

    context "photo_referenceが空の写真がある場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/details\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            result: {
              name: "テストスポット",
              formatted_address: "東京都",
              photos: [
                { photo_reference: "valid_ref" },
                { photo_reference: "" },
                { photo_reference: nil },
                { other_field: "no_ref" }
              ]
            }
          }.to_json)
      end

      it "空のphoto_referenceをスキップする" do
        result = GoogleApi::Places.fetch_details("ChIJ12345")

        expect(result[:photo_urls].length).to eq(1)
        expect(result[:photo_urls].first).to include("valid_ref")
      end
    end
  end

  describe ".text_search" do
    context "クエリが空の場合" do
      it "空配列を返す" do
        expect(GoogleApi::Places.text_search("", lat: 35.0, lng: 139.0)).to eq([])
        expect(GoogleApi::Places.text_search(nil, lat: 35.0, lng: 139.0)).to eq([])
      end
    end

    context "APIが正常なレスポンスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/textsearch\/json/)
          .to_return(status: 200, body: {
            status: "OK",
            results: [
              {
                place_id: "ChIJ111",
                name: "ラーメン一郎",
                formatted_address: "日本、〒100-0001 東京都千代田区",
                geometry: { location: { lat: 35.68, lng: 139.76 } }
              },
              {
                place_id: "ChIJ222",
                name: "ラーメン二郎",
                formatted_address: "東京都渋谷区",
                geometry: { location: { lat: 35.66, lng: 139.70 } }
              }
            ]
          }.to_json)
      end

      it "複数のスポット情報を返す" do
        results = GoogleApi::Places.text_search("ラーメン", lat: 35.68, lng: 139.76)

        expect(results.length).to eq(2)
        expect(results.first[:place_id]).to eq("ChIJ111")
        expect(results.first[:name]).to eq("ラーメン一郎")
        expect(results.first[:lat]).to eq(35.68)
        expect(results.first[:lng]).to eq(139.76)
      end

      it "住所を正規化する" do
        results = GoogleApi::Places.text_search("ラーメン", lat: 35.68, lng: 139.76)

        expect(results.first[:address]).to eq("東京都千代田区")
        expect(results.first[:address]).not_to include("日本")
      end
    end

    context "検索結果が0件の場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/textsearch\/json/)
          .to_return(status: 200, body: { status: "ZERO_RESULTS", results: [] }.to_json)
      end

      it "空配列を返す" do
        results = GoogleApi::Places.text_search("存在しないクエリ", lat: 35.0, lng: 139.0)

        expect(results).to eq([])
      end
    end

    context "APIがエラーステータスを返す場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/textsearch\/json/)
          .to_return(status: 200, body: { status: "REQUEST_DENIED" }.to_json)
      end

      it "空配列を返す" do
        results = GoogleApi::Places.text_search("ラーメン", lat: 35.0, lng: 139.0)

        expect(results).to eq([])
      end
    end

    context "通信エラーが発生した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/textsearch\/json/)
          .to_raise(StandardError.new("connection timeout"))
      end

      it "空配列を返す" do
        results = GoogleApi::Places.text_search("ラーメン", lat: 35.0, lng: 139.0)

        expect(results).to eq([])
      end
    end

    context "radiusを指定した場合" do
      before do
        stub_request(:get, /maps.googleapis.com\/maps\/api\/place\/textsearch\/json/)
          .with(query: hash_including(radius: "10000"))
          .to_return(status: 200, body: { status: "OK", results: [] }.to_json)
      end

      it "指定したradiusでリクエストする" do
        GoogleApi::Places.text_search("カフェ", lat: 35.0, lng: 139.0, radius: 10000)

        expect(WebMock).to have_requested(:get, /textsearch/)
          .with(query: hash_including(radius: "10000"))
      end
    end
  end
end
