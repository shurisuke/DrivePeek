# app/services/reverse_geocoder.rb
require 'net/http'
require 'uri'
require 'json'

class ReverseGeocoder
  FALLBACK_LOCATION = {
    lat: 35.681236,
    lng: 139.767125,
    address: '東京都千代田区丸の内一丁目',
    prefecture: '東京都',
    city: '千代田区'
  }

  GOOGLE_GEOCODING_API_URL = "https://maps.googleapis.com/maps/api/geocode/json"

  def self.lookup_address(lat:, lng:)
    Rails.logger.debug "[DEBUG] lookup_address called with lat=#{lat}, lng=#{lng}"

    return FALLBACK_LOCATION unless lat.present? && lng.present?

    uri = URI.parse(GOOGLE_GEOCODING_API_URL)
    uri.query = URI.encode_www_form({
      latlng: "#{lat},#{lng}",
      key: ENV["GOOGLE_MAPS_API_KEY"],
      language: "ja"
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # ← 開発中のみ

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)

    Rails.logger.debug "[DEBUG] Google Geocoding API response:"
    Rails.logger.debug JSON.pretty_generate(json)

    if json["status"] == "OK"
      result = json["results"].first

      address = result["formatted_address"]
      components = result["address_components"]

      prefecture = components.find { |c| c["types"].include?("administrative_area_level_1") }&.dig("long_name")
      city = components.find { |c| c["types"].include?("locality") || c["types"].include?("sublocality_level_1") }&.dig("long_name")

      {
        lat: lat,
        lng: lng,
        address: address,
        prefecture: prefecture || "不明",
        city: city || "不明"
      }
    else
      Rails.logger.error "Geocoding API error: #{json["status"]}"
      FALLBACK_LOCATION
    end
  rescue => e
    Rails.logger.error "Geocoding failed: #{e.message}"
    FALLBACK_LOCATION
  end
end