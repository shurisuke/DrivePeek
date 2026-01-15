# OpenAI API を使用してスポットのジャンルを判定する
#
# 使い方:
#   genre_ids = GenreDetector.detect(spot)
#   # => [5, 9] (海・海岸, 絶景・展望 のID)
#
#   # 既存ジャンルを除外して不足分のみ判定
#   genre_ids = GenreDetector.detect(spot, count: 1, exclude_ids: [1])
#
class GenreDetector
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 256

  class << self
    # スポット情報から適切なジャンルを AI で判定
    #
    # @param spot [Spot] ジャンルを判定するスポット
    # @param count [Integer] 判定するジャンル数（デフォルト: 2）
    # @param exclude_ids [Array<Integer>] 除外するジャンルID
    # @return [Array<Integer>] 判定された Genre の ID 配列
    def detect(spot, count: 2, exclude_ids: [])
      return [] unless api_key_configured?

      response = call_api(spot, count: count, exclude_ids: exclude_ids)
      parse_response(response, count: count)
    rescue Faraday::Error => e
      Rails.logger.error "[GenreDetector] OpenAI API error: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "[GenreDetector] Unexpected error: #{e.class} - #{e.message}"
      []
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    def call_api(spot, count:, exclude_ids:)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: [
            { role: "user", content: build_prompt(spot, count: count, exclude_ids: exclude_ids) }
          ]
        }
      )
    end

    # AIに選ばせない汎用ジャンル（より具体的なジャンルを選ばせる）
    # facility は GenreDetectionJob でフォールバックとして使用
    EXCLUDED_SLUGS = %w[gourmet facility].freeze

    def build_prompt(spot, count:, exclude_ids:)
      # 子を持つ親ジャンルは除外（より具体的な子ジャンルを選ばせる）
      parent_ids = Genre.joins(:children).distinct.pluck(:id)
      # 汎用ジャンルも除外
      fallback_ids = Genre.where(slug: EXCLUDED_SLUGS).pluck(:id)
      available_genres = Genre.ordered.where.not(id: exclude_ids + parent_ids + fallback_ids)
      genres_list = available_genres.pluck(:slug, :name).map { |slug, name| "#{slug}: #{name}" }.join("\n")

      <<~PROMPT
        以下のスポット情報から、最も適切なジャンルをちょうど#{count}個選んでください。

        【スポット情報】
        名前: #{spot.name}
        住所: #{spot.address}
        都道府県: #{spot.prefecture}
        市区町村: #{spot.city}

        【選択可能なジャンル】
        #{genres_list}

        【注意事項】
        - 確実に該当するジャンルのみ選んでください
        - world_heritage（世界遺産）はUNESCO登録済みの場所のみ選択してください
        - 不確かな場合は、より一般的なジャンル（mountain, park等）を選んでください

        【回答形式】
        ジャンルのslug（英語）をカンマ区切りで回答してください。必ず#{count}個選んでください。
        例: ramen,night_view

        回答:
      PROMPT
    end

    def parse_response(response, count:)
      return [] if response.nil?

      # OpenAI のレスポンスからテキストを取得
      content = response.dig("choices", 0, "message", "content")
      return [] if content.blank?

      text = content.to_s.strip.downcase

      # slug をパースして Genre ID に変換（指定数に制限）
      slugs = text.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      Genre.where(slug: slugs).pluck(:id).take(count)
    end
  end
end
