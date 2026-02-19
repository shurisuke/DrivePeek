# frozen_string_literal: true

# 責務: Google Directions API を呼び出し、経路情報を取得する
#
# 提供メソッド:
#   - fetch: 2点間の経路を取得（移動時間、距離、ポリライン）
#
# 注意: エラー時はnilを返す。フォールバック値はドメイン層で決定すること。
#
class GoogleApi::Directions
  API_URL = "https://maps.googleapis.com/maps/api/directions/json"

  class << self
    # 2点間の経路を取得
    # @param origin [Hash] { lat:, lng: }
    # @param destination [Hash] { lat:, lng: }
    # @param toll_used [Boolean] 有料道路を使用するか
    # @return [Hash, nil] { move_time:, move_distance:, polyline: } or nil
    def fetch(origin:, destination:, toll_used: false)
      return nil unless valid_coordinates?(origin, destination)

      uri = build_uri(origin, destination, toll_used)
      response = GoogleApi.fetch_json(uri, timeout: 10)
      parse_response(response)
    rescue StandardError => e
      Rails.logger.error "[GoogleApi::Directions] API error: #{e.message}"
      nil
    end

    private

    def valid_coordinates?(origin, destination)
      [ origin[:lat], origin[:lng], destination[:lat], destination[:lng] ].all?(&:present?)
    end

    def build_uri(origin, destination, toll_used)
      uri = URI.parse(API_URL)

      params = {
        origin: "#{origin[:lat]},#{origin[:lng]}",
        destination: "#{destination[:lat]},#{destination[:lng]}",
        mode: "driving",
        language: "ja",
        region: "jp",
        key: GoogleApi.api_key
      }

      # toll_used = false の場合は有料道路を回避
      params[:avoid] = "tolls" unless toll_used

      uri.query = URI.encode_www_form(params)
      uri
    end

    def parse_response(json)
      unless json["status"] == "OK"
        Rails.logger.warn "[GoogleApi::Directions] API returned status: #{json['status']}"
        return nil
      end

      route = json.dig("routes", 0)
      return nil unless route

      leg = route.dig("legs", 0)
      return nil unless leg

      {
        move_time: parse_duration(leg["duration"]),
        move_distance: parse_distance(leg["distance"]),
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
