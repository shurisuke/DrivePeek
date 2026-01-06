# Claude API を使用してスポットのジャンルを判定する
#
# 使い方:
#   genre_ids = GenreDetector.detect(spot)
#   # => [5, 9] (海・海岸, 絶景・展望 のID)
#
class GenreDetector
  MODEL = "claude-3-5-haiku-latest".freeze
  MAX_TOKENS = 256

  class << self
    # スポット情報から適切なジャンルを AI で判定
    #
    # @param spot [Spot] ジャンルを判定するスポット
    # @return [Array<Integer>] 判定された Genre の ID 配列
    def detect(spot)
      return [] unless api_key_configured?

      response = call_api(spot)
      parse_response(response)
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

    def call_api(spot)
      client = Anthropic::Client.new

      client.messages.create(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        messages: [
          { role: "user", content: build_prompt(spot) }
        ]
      )
    end

    def build_prompt(spot)
      genres_list = Genre.ordered.pluck(:slug, :name).map { |slug, name| "#{slug}: #{name}" }.join("\n")

      <<~PROMPT
        以下のスポット情報から、最も適切なジャンルを1〜3個選んでください。

        【スポット情報】
        名前: #{spot.name}
        住所: #{spot.address}
        都道府県: #{spot.prefecture}
        市区町村: #{spot.city}

        【選択可能なジャンル】
        #{genres_list}

        【回答形式】
        ジャンルのslug（英語）をカンマ区切りで回答してください。
        例: gourmet,cafe

        回答:
      PROMPT
    end

    def parse_response(response)
      return [] if response.nil?

      # Claude のレスポンスからテキストを取得
      content = response.content.first
      return [] unless content.is_a?(Hash) && content[:type] == "text"

      text = content[:text].to_s.strip.downcase

      # slug をパースして Genre ID に変換
      slugs = text.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      Genre.where(slug: slugs).pluck(:id)
    end
  end
end
