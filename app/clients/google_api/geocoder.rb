# frozen_string_literal: true

# 責務: Google Geocoding API を呼び出し、住所と座標を相互変換する
#
# 提供メソッド:
#   - forward: 住所から緯度経度を取得
#   - reverse: 緯度経度から住所を取得
#
# 注意: エラー時はnilを返す。フォールバック値はドメイン層で決定すること。
#
class GoogleApi::Geocoder
  API_URL = "https://maps.googleapis.com/maps/api/geocode/json"

  class << self
    # 住所から緯度経度を取得（Forward Geocoding）
    # @param address [String] 住所文字列
    # @return [Hash, nil] { lat:, lng:, prefecture: } or nil
    def forward(address)
      return nil if address.blank?

      uri = build_uri(address: address)
      json = GoogleApi.fetch_json(uri)

      if json["status"] == "OK"
        result = json["results"].first
        location = result.dig("geometry", "location")
        components = result["address_components"] || []

        prefecture = components.find { |c| c["types"].include?("administrative_area_level_1") }&.dig("long_name")

        { lat: location["lat"], lng: location["lng"], prefecture: prefecture }
      else
        Rails.logger.warn "[GoogleApi::Geocoder] forward failed: #{json['status']}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Geocoder] forward error: #{e.message}"
      nil
    end

    # 緯度経度から住所を取得（Reverse Geocoding）
    # @param lat [Float] 緯度
    # @param lng [Float] 経度
    # @return [Hash, nil] { lat:, lng:, address:, prefecture:, city:, town: } or nil
    def reverse(lat:, lng:)
      return nil unless lat.present? && lng.present?

      uri = build_uri(latlng: "#{lat},#{lng}")
      json = GoogleApi.fetch_json(uri)

      if json["status"] == "OK"
        result = json["results"].first
        components = result["address_components"] || []

        {
          lat: lat,
          lng: lng,
          address: GoogleApi.normalize_address(result["formatted_address"].to_s),
          prefecture: extract_component(components, "administrative_area_level_1"),
          city: extract_component(components, "locality", "sublocality_level_1"),
          town: extract_component(components, "sublocality_level_2", "sublocality_level_3", "neighborhood")
        }
      else
        Rails.logger.error "[GoogleApi::Geocoder] reverse failed: #{json['status']}"
        nil
      end
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Geocoder] reverse error: #{e.message}"
      nil
    end

    private

    def build_uri(params)
      uri = URI.parse(API_URL)
      uri.query = URI.encode_www_form(
        params.merge(
          key: GoogleApi.api_key,
          language: "ja",
          region: "jp"
        )
      )
      uri
    end

    def extract_component(components, *types)
      components.find { |c| (c["types"] & types).any? }&.dig("long_name")
    end
  end
end
