# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# Google Places API でスポット詳細を取得
# InfoWindowのTurbo Frame方式でサーバー側からplace_idでスポット名・住所・写真を取得
class PlaceDetailsService
  GOOGLE_PLACES_API_URL = "https://maps.googleapis.com/maps/api/place/details/json"
  GOOGLE_PHOTO_API_URL = "https://maps.googleapis.com/maps/api/place/photo"

  def self.fetch(place_id:, include_photos: true)
    return nil if place_id.blank?

    fields = %w[name formatted_address]
    fields << "photos" if include_photos

    uri = URI.parse(GOOGLE_PLACES_API_URL)
    uri.query = URI.encode_www_form({
      place_id: place_id,
      fields: fields.join(","),
      key: ENV["GOOGLE_MAPS_API_KEY"],
      language: "ja"
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 3
    http.read_timeout = 3

    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    json = JSON.parse(response.body)

    if json["status"] == "OK"
      result = json["result"]
      {
        name: result["name"],
        address: normalize_address(result["formatted_address"]),
        photo_urls: build_photo_urls(result["photos"])
      }
    else
      Rails.logger.warn "[PlaceDetailsService] API error: #{json["status"]} for place_id=#{place_id}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "[PlaceDetailsService] Error: #{e.message}"
    nil
  end

  # photo_reference から実際の画像URLを構築
  def self.build_photo_urls(photos, max_count: 5, max_width: 520)
    return [] if photos.blank?

    photos.first(max_count).filter_map do |photo|
      ref = photo["photo_reference"]
      next if ref.blank?

      "#{GOOGLE_PHOTO_API_URL}?maxwidth=#{max_width}&photo_reference=#{ref}&key=#{ENV["GOOGLE_MAPS_API_KEY"]}"
    end
  end

  def self.normalize_address(address)
    return nil if address.blank?

    a = address.dup
    a.sub!(/\A日本[、,\s]*/u, "")
    a.sub!(/\A〒\s*\d{3}[‐-‒–—−-]\d{4}\s*/u, "")
    a.sub!(/\A[、,\s]+/u, "")
    a.strip
  end
end
