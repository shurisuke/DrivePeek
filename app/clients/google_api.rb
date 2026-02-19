# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# 責務: Google API クライアント群の共通処理を提供する
#
# 提供メソッド:
#   - fetch_json: HTTP GET でJSONを取得
#   - api_key: Google Maps API キーを取得
#   - normalize_address: 住所を正規化（国名・郵便番号を除去）
#
module GoogleApi
  class << self
    # HTTP GET でJSONを取得
    # @param uri [URI] リクエストURI
    # @param timeout [Integer] タイムアウト秒数
    # @return [Hash] パースされたJSON
    def fetch_json(uri, timeout: 5)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = timeout
      http.read_timeout = timeout

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      JSON.parse(response.body)
    end

    # Google Maps API キーを取得
    # @return [String, nil]
    def api_key
      ENV["GOOGLE_MAPS_API_KEY"]
    end

    # 住所を正規化（国名・郵便番号を除去）
    # 例: "日本、〒329-1117 栃木県宇都宮市" → "栃木県宇都宮市"
    # @param address [String]
    # @return [String, nil]
    def normalize_address(address)
      return nil if address.blank?

      a = address.dup
      a.sub!(/\A日本[、,\s]*/u, "")
      a.sub!(/\A〒\s*\d{3}[‐-‒–—−-]\d{4}\s*/u, "")
      a.sub!(/\A[、,\s]+/u, "")
      a.strip
    end
  end
end
