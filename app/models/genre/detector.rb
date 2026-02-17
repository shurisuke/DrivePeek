# frozen_string_literal: true

# OpenAI API を使用してスポットのジャンルを判定する
#
# 使い方:
#   genre_ids = Genre::Detector.detect(spot)
#   # => [5, 9] (海・海岸, 絶景・展望 のID)
#
class Genre::Detector
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 256

  class << self
    # @param spot [Spot] ジャンルを判定するスポット
    # @param count [Integer] 判定するジャンル数（デフォルト: 2）
    # @return [Array<Integer>] 判定された Genre の ID 配列
    def detect(spot, count: 2)
      return [] unless api_key_configured?

      response = call_api(spot, count: count)
      parse_response(response, count: count)
    rescue Faraday::Error => e
      Rails.logger.error "[Genre::Detector] OpenAI API error: #{e.message}"
      []
    rescue StandardError => e
      Rails.logger.error "[Genre::Detector] Unexpected error: #{e.class} - #{e.message}"
      []
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    def call_api(spot, count:)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: [
            { role: "user", content: build_prompt(spot, count: count) }
          ]
        }
      )
    end

    # スポットに紐付けない親ジャンル（子ジャンルを選ばせる）
    PARENT_SLUGS = %w[shopping sports_ground].freeze

    # 観光名所と同時選択された場合、観光名所を外すジャンル
    EXCLUDE_SIGHTSEEING_WITH = %w[park shrine_temple mountain].freeze

    def build_prompt(spot, count:)
      # 親ジャンルは汎用的すぎるので除外（子ジャンルを選ばせる）
      genres_list = Genre.ordered.where.not(slug: PARENT_SLUGS).pluck(:slug, :name).map { |slug, name| "#{slug}: #{name}" }.join("\n")

      <<~PROMPT
        以下のスポット情報から、最も適切なジャンルを選んでください。
        ・1個目は必ず選んでください
        ・2個目は本当に当てはまる場合のみ選んでください（無理に選ばない）

        【スポット情報】
        名前: #{spot.name}
        住所: #{spot.address}

        【選択可能なジャンル】
        #{genres_list}

        【回答形式】
        ジャンルのslug（英語）をカンマ区切りで回答してください。
        例: ramen,night_view または ramen

        回答:
      PROMPT
    end

    def parse_response(response, count:)
      return [] if response.nil?

      content = response.dig("choices", 0, "message", "content")
      return [] if content.blank?

      slugs = content.to_s.strip.downcase.split(/[,\s]+/).map(&:strip).reject(&:blank?)
      slugs = slugs.reject { |s| s == "none" } # 「none」は除外
      slugs = exclude_sightseeing_if_needed(slugs)
      Genre.where(slug: slugs).pluck(:id).take(count)
    end

    # 特定ジャンルと観光名所が同時に選ばれた場合、観光名所を外す
    def exclude_sightseeing_if_needed(slugs)
      return slugs unless slugs.include?("sightseeing")
      return slugs unless (slugs & EXCLUDE_SIGHTSEEING_WITH).any?

      slugs - [ "sightseeing" ]
    end
  end
end
