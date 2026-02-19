# frozen_string_literal: true

# 責務: Google Places API を呼び出し、スポット情報を取得する
#
# 提供メソッド:
#   - find_by_name: 名前からスポットを検索
#   - fetch_details: place_idから詳細を取得
#   - text_search: テキスト検索で複数スポットを取得
#
class GoogleApi::Places
  FIND_PLACE_API_URL = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json"
  TEXT_SEARCH_API_URL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
  DETAILS_API_URL = "https://maps.googleapis.com/maps/api/place/details/json"
  PHOTO_API_URL = "https://maps.googleapis.com/maps/api/place/photo"

  class << self
    # 名前からスポットを検索
    # @param name [String] スポット名
    # @param lat [Float] 検索の中心緯度（バイアス用）
    # @param lng [Float] 検索の中心経度（バイアス用）
    # @return [Hash, nil] { place_id:, name:, lat:, lng: } or nil
    def find_by_name(name, lat: nil, lng: nil)
      return nil if name.blank?

      uri = build_find_place_uri(name, lat, lng)
      json = GoogleApi.fetch_json(uri)
      parse_find_place_response(json)
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Places] find_by_name error: #{e.message}"
      nil
    end

    # place_idから詳細を取得
    # @param place_id [String] Google Place ID
    # @param include_photos [Boolean] 写真を含めるか
    # @return [Hash, nil] { name:, address:, photo_urls: } or nil
    def fetch_details(place_id, include_photos: true)
      return nil if place_id.blank?

      uri = build_details_uri(place_id, include_photos)
      json = GoogleApi.fetch_json(uri)
      parse_details_response(json, place_id)
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Places] fetch_details error: #{e.message}"
      nil
    end

    # テキスト検索で複数スポットを取得
    # @param query [String] 検索クエリ（例: "ラーメン"）
    # @param lat [Float] 中心緯度
    # @param lng [Float] 中心経度
    # @param radius [Integer] 検索半径（メートル、最大50000）
    # @return [Array<Hash>] [{ place_id:, name:, address:, lat:, lng: }, ...]
    def text_search(query, lat:, lng:, radius: 5000)
      return [] if query.blank?

      uri = build_text_search_uri(query, lat, lng, radius)
      json = GoogleApi.fetch_json(uri)
      parse_text_search_response(json)
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Places] text_search error: #{e.message}"
      []
    end

    private

    # --- find_by_name 関連 ---

    def build_find_place_uri(name, lat, lng)
      uri = URI.parse(FIND_PLACE_API_URL)

      params = {
        input: name,
        inputtype: "textquery",
        fields: "place_id,name,geometry",
        language: "ja",
        key: GoogleApi.api_key
      }

      # 位置バイアス（指定座標付近を優先）
      params[:locationbias] = "point:#{lat},#{lng}" if lat.present? && lng.present?

      uri.query = URI.encode_www_form(params)
      uri
    end

    def parse_find_place_response(json)
      unless json["status"] == "OK"
        Rails.logger.warn "[GoogleApi::Places] find_by_name API status: #{json['status']}"
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

    # --- fetch_details 関連 ---

    def build_details_uri(place_id, include_photos)
      uri = URI.parse(DETAILS_API_URL)

      fields = %w[name formatted_address]
      fields << "photos" if include_photos

      uri.query = URI.encode_www_form({
        place_id: place_id,
        fields: fields.join(","),
        key: GoogleApi.api_key,
        language: "ja"
      })
      uri
    end

    def parse_details_response(json, place_id)
      unless json["status"] == "OK"
        Rails.logger.warn "[GoogleApi::Places] fetch_details API error: #{json['status']} for place_id=#{place_id}"
        return nil
      end

      result = json["result"]
      {
        name: result["name"],
        address: GoogleApi.normalize_address(result["formatted_address"]),
        photo_urls: build_photo_urls(result["photos"])
      }
    end

    def build_photo_urls(photos, max_count: 5, max_width: 520)
      return [] if photos.blank?

      photos.first(max_count).filter_map do |photo|
        ref = photo["photo_reference"]
        next if ref.blank?

        "#{PHOTO_API_URL}?maxwidth=#{max_width}&photo_reference=#{ref}&key=#{GoogleApi.api_key}"
      end
    end

    # --- text_search 関連 ---

    def build_text_search_uri(query, lat, lng, radius)
      uri = URI.parse(TEXT_SEARCH_API_URL)

      uri.query = URI.encode_www_form({
        query: query,
        location: "#{lat},#{lng}",
        radius: radius,
        language: "ja",
        key: GoogleApi.api_key
      })
      uri
    end

    def parse_text_search_response(json)
      unless json["status"] == "OK" || json["status"] == "ZERO_RESULTS"
        Rails.logger.warn "[GoogleApi::Places] text_search API status: #{json['status']}"
        return []
      end

      results = json["results"] || []
      results.map do |result|
        location = result.dig("geometry", "location")
        {
          place_id: result["place_id"],
          name: result["name"],
          address: GoogleApi.normalize_address(result["formatted_address"]),
          lat: location&.dig("lat"),
          lng: location&.dig("lng")
        }
      end
    end
  end
end
