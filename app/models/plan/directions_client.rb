# app/models/plan/directions_client.rb
# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

# 責務: Google Directions API を呼び出し、経路情報を取得する
#
# 入力:
#   - origin (lat, lng)
#   - destination (lat, lng)
#   - toll_used
#
# 出力:
#   - move_time（分）
#   - move_distance（km）
#   - move_cost（Phase 2 では 0 固定）
#   - polyline
#
class Plan::DirectionsClient
  GOOGLE_DIRECTIONS_API_URL = "https://maps.googleapis.com/maps/api/directions/json"

  # APIエラー時に使用するフォールバック結果
  FALLBACK_RESULT = {
    move_time: 0,
    move_distance: 0.0,
    move_cost: 0,
    polyline: nil
  }.freeze

  class << self
    # 2点間の経路を取得
    # @param origin [Hash] { lat:, lng: }
    # @param destination [Hash] { lat:, lng: }
    # @param toll_used [Boolean] 有料道路を使用するか
    # @return [Hash] { move_time:, move_distance:, move_cost:, polyline: }
    def fetch(origin:, destination:, toll_used: false)
      return FALLBACK_RESULT.dup unless valid_coordinates?(origin, destination)

      response = call_api(origin, destination, toll_used)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "[DirectionsClient] API error: #{e.message}"
      FALLBACK_RESULT.dup
    end

    private

    def valid_coordinates?(origin, destination)
      [origin[:lat], origin[:lng], destination[:lat], destination[:lng]].all?(&:present?)
    end

    def call_api(origin, destination, toll_used)
      uri = build_uri(origin, destination, toll_used)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      JSON.parse(response.body)
    end

    def build_uri(origin, destination, toll_used)
      uri = URI.parse(GOOGLE_DIRECTIONS_API_URL)

      params = {
        origin: "#{origin[:lat]},#{origin[:lng]}",
        destination: "#{destination[:lat]},#{destination[:lng]}",
        mode: "driving",
        language: "ja",
        region: "jp",
        key: api_key
      }

      # toll_used = false の場合は有料道路を回避
      params[:avoid] = "tolls" unless toll_used

      uri.query = URI.encode_www_form(params)
      uri
    end

    def api_key
      ENV["GOOGLE_MAPS_API_KEY"]
    end

    def parse_response(json)
      unless json["status"] == "OK"
        Rails.logger.warn "[DirectionsClient] API returned status: #{json['status']}"
        return FALLBACK_RESULT.dup
      end

      route = json.dig("routes", 0)
      return FALLBACK_RESULT.dup unless route

      leg = route.dig("legs", 0)
      return FALLBACK_RESULT.dup unless leg

      {
        move_time: parse_duration(leg["duration"]),
        move_distance: parse_distance(leg["distance"]),
        move_cost: 0, # Phase 2 では 0 固定
        polyline: route.dig("overview_polyline", "points")
      }
    end

    # duration を分に変換
    # @param duration [Hash] { value: 秒, text: "1時間30分" }
    # @return [Integer] 分
    def parse_duration(duration)
      return 0 unless duration && duration["value"]

      (duration["value"] / 60.0).ceil
    end

    # distance を km に変換
    # @param distance [Hash] { value: メートル, text: "10.5 km" }
    # @return [Float] km
    def parse_distance(distance)
      return 0.0 unless distance && distance["value"]

      (distance["value"] / 1000.0).round(1)
    end
  end
end
