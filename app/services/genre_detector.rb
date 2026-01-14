# Claude API を使用してスポットのジャンルを判定する
#
# 使い方:
#   genre_ids = GenreDetector.detect(spot)
#   # => [5, 9] (海・海岸, 絶景・展望 のID)
#
#   # 既存ジャンルを除外して不足分のみ判定
#   genre_ids = GenreDetector.detect(spot, count: 1, exclude_ids: [1])
#
class GenreDetector
  MODEL = "claude-3-5-haiku-latest".freeze
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
    rescue Anthropic::Errors::APIError => e
      Rails.logger.error "[GenreDetector] Anthropic API error: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "[GenreDetector] Unexpected error: #{e.class} - #{e.message}"
      []
    end

    private

    def api_key_configured?
      ENV["ANTHROPIC_API_KEY"].present?
    end

    def call_api(spot, count:, exclude_ids:)
      client = Anthropic::Client.new

      client.messages.create(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        messages: [
          { role: "user", content: build_prompt(spot, count: count, exclude_ids: exclude_ids) }
        ]
      )
    end

    def build_prompt(spot, count:, exclude_ids:)
      available_genres = Genre.ordered.where.not(id: exclude_ids)
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

        【回答形式】
        ジャンルのslug（英語）をカンマ区切りで回答してください。必ず#{count}個選んでください。
        例: gourmet,cafe

        回答:
      PROMPT
    end

    def parse_response(response, count:)
      return [] if response.nil?

      # Claude のレスポンスからテキストを取得
      content = response.content.first
      return [] unless content.is_a?(Hash) && content[:type] == "text"

      text = content[:text].to_s.strip.downcase

      # slug をパースして Genre ID に変換（指定数に制限）
      slugs = text.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      Genre.where(slug: slugs).pluck(:id).take(count)
    end
  end
end
