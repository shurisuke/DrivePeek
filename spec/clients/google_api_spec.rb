# frozen_string_literal: true

require "rails_helper"

RSpec.describe GoogleApi do
  describe ".api_key" do
    it "GOOGLE_MAPS_API_KEYを返す" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("GOOGLE_MAPS_API_KEY").and_return("test-api-key")

      expect(GoogleApi.api_key).to eq("test-api-key")
    end
  end

  describe ".fetch_json" do
    let(:uri) { URI.parse("https://example.com/api?key=test") }

    context "正常なレスポンスの場合" do
      before do
        stub_request(:get, "https://example.com/api?key=test")
          .to_return(status: 200, body: { result: "success" }.to_json)
      end

      it "パースされたJSONを返す" do
        result = GoogleApi.fetch_json(uri)

        expect(result).to eq({ "result" => "success" })
      end
    end

    context "タイムアウトを指定した場合" do
      before do
        stub_request(:get, "https://example.com/api?key=test")
          .to_return(status: 200, body: { ok: true }.to_json)
      end

      it "指定されたタイムアウトでリクエストする" do
        http_double = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:new).and_return(http_double)
        allow(http_double).to receive(:use_ssl=)
        allow(http_double).to receive(:open_timeout=)
        allow(http_double).to receive(:read_timeout=)
        allow(http_double).to receive(:request).and_return(
          instance_double(Net::HTTPResponse, body: { ok: true }.to_json)
        )

        GoogleApi.fetch_json(uri, timeout: 15)

        expect(http_double).to have_received(:open_timeout=).with(15)
        expect(http_double).to have_received(:read_timeout=).with(15)
      end
    end
  end

  describe ".normalize_address" do
    it "国名を削除する" do
      expect(GoogleApi.normalize_address("日本、東京都")).to eq("東京都")
    end

    it "郵便番号を削除する" do
      expect(GoogleApi.normalize_address("〒100-0001 東京都千代田区")).to eq("東京都千代田区")
    end

    it "国名と郵便番号を両方削除する" do
      expect(GoogleApi.normalize_address("日本、〒100-0001 東京都千代田区")).to eq("東京都千代田区")
    end

    it "全角ハイフンの郵便番号も処理する" do
      expect(GoogleApi.normalize_address("〒329−1117 栃木県")).to eq("栃木県")
    end

    it "空文字の場合nilを返す" do
      expect(GoogleApi.normalize_address("")).to be_nil
    end

    it "nilの場合nilを返す" do
      expect(GoogleApi.normalize_address(nil)).to be_nil
    end
  end
end
