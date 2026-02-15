require "net/http"
require "uri"
require "json"

class ReverseGeocoder
  FALLBACK_LOCATION = {
    lat: 35.681236,
    lng: 139.767125,
    address: "東京都千代田区丸の内一丁目",
    prefecture: "東京都",
    city: "千代田区"
  }

  GOOGLE_GEOCODING_API_URL = "https://maps.googleapis.com/maps/api/geocode/json"

  # 住所から緯度経度を取得（Forward Geocoding）
  # @return [Hash, nil] { lat:, lng:, prefecture: } or nil
  def self.geocode_address(address)
    return nil if address.blank?

    uri = URI.parse(GOOGLE_GEOCODING_API_URL)
    uri.query = URI.encode_www_form({
      address: address,
      key: ENV["GOOGLE_MAPS_API_KEY"],
      language: "ja",
      region: "jp"
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)

    if json["status"] == "OK"
      result = json["results"].first
      location = result.dig("geometry", "location")
      components = result["address_components"] || []

      # 都道府県を抽出
      prefecture = components.find { |c| c["types"].include?("administrative_area_level_1") }&.dig("long_name")

      { lat: location["lat"], lng: location["lng"], prefecture: prefecture }
    else
      Rails.logger.warn "[ReverseGeocoder] geocode_address failed: #{json['status']}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[ReverseGeocoder] geocode_address error: #{e.message}"
    nil
  end

  def self.lookup_address(lat:, lng:)
    Rails.logger.debug "[DEBUG] lookup_address called with lat=#{lat}, lng=#{lng}"

    return FALLBACK_LOCATION unless lat.present? && lng.present?

    uri = URI.parse(GOOGLE_GEOCODING_API_URL)
    uri.query = URI.encode_www_form({
      latlng: "#{lat},#{lng}",
      key: ENV["GOOGLE_MAPS_API_KEY"],
      language: "ja",
      region: "jp"
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)

    Rails.logger.debug "[DEBUG] Google Geocoding API response:"
    Rails.logger.debug JSON.pretty_generate(json)

    if json["status"] == "OK"
      result = json["results"].first

      raw_address = result["formatted_address"].to_s
      address = normalize_address(raw_address)

      components = result["address_components"] || []

      prefecture =
        components.find { |c| c["types"].include?("administrative_area_level_1") }&.dig("long_name")

      city =
        components.find { |c| c["types"].include?("locality") || c["types"].include?("sublocality_level_1") }&.dig("long_name")

      # 町名（sublocality_level_2, sublocality_level_3, neighborhood等）
      town =
        components.find { |c|
          (c["types"] & [ "sublocality_level_2", "sublocality_level_3", "neighborhood" ]).any?
        }&.dig("long_name")

      {
        lat: lat,
        lng: lng,
        address: address, # ← ここに「栃木県宇都宮市叶谷町４７−１１１」だけ入る
        prefecture: prefecture || "不明",
        city: city || "不明",
        town: town
      }
    else
      Rails.logger.error "Geocoding API error: #{json["status"]}"
      FALLBACK_LOCATION
    end
  rescue => e
    Rails.logger.error "Geocoding failed: #{e.message}"
    FALLBACK_LOCATION
  end

  # 例:
  # "日本、〒329-1117 栃木県宇都宮市叶谷町４７−１１１"
  # → "栃木県宇都宮市叶谷町４７−１１１"
  def self.normalize_address(address)
    a = address.dup

    # 先頭の国名（日本、）を削除
    a.sub!(/\A日本[、,\s]*/u, "")

    # 先頭の郵便番号（〒123-4567 / 〒123−4567 などハイフン差異も吸収）を削除
    a.sub!(/\A〒\s*\d{3}[‐-‒–—−-]\d{4}\s*/u, "")

    # 先頭に残りがちな記号/空白を削除
    a.sub!(/\A[、,\s]+/u, "")

    a.strip
  end
end
