# frozen_string_literal: true

# Google Places API アダプター
# 外部APIとのやり取りを抽象化し、アプリケーション用の形式に変換
class GooglePlacesAdapter
  GOOGLE_FIND_PLACE_API_URL = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"

  class << self
    # 名前からPOIを検索してplace_idを取得
    # @param name [String] スポット名
    # @param lat [Float] 検索の中心緯度（バイアス用）
    # @param lng [Float] 検索の中心経度（バイアス用）
    # @return [Hash, nil] { place_id:, name:, lat:, lng: } or nil
    def find_place(name:, lat: nil, lng: nil)
      return nil if name.blank?

      uri = build_uri(name, lat, lng)
      response = fetch(uri)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "[GooglePlacesAdapter] Error: #{e.message}"
      nil
    end

    private

    def build_uri(name, lat, lng)
      uri = URI.parse(GOOGLE_FIND_PLACE_API_URL)

      params = {
        input: name,
        inputtype: "textquery",
        fields: "place_id,name,geometry",
        language: "ja",
        key: ENV["GOOGLE_MAPS_API_KEY"]
      }

      # 位置バイアス（指定座標付近を優先）
      if lat.present? && lng.present?
        params[:locationbias] = "point:#{lat},#{lng}"
      end

      uri.query = URI.encode_www_form(params)
      uri
    end

    def fetch(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      JSON.parse(response.body)
    end

    def parse_response(json)
      unless json["status"] == "OK"
        Rails.logger.warn "[GooglePlacesAdapter] API status: #{json['status']}"
        return nil
      end

      candidate = json.dig("candidates", 0)
      return nil unless candidate

      location = candidate.dig("geometry", "location")

      {
        place_id: candidate["place_id"],
        name: candidate["name"],
        lat: location&.dig("lat"),
        lng: location&.dig("lng")
      }
    end
  end
end
