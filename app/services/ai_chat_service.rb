# OpenAI API を使用してドライブプランの提案を行う
#
# 使い方:
#   response = AiChatService.chat(message, plan: plan)
#   # => "栃木の日帰りドライブですね！..."
#
class AiChatService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  class << self
    # @param message [String] ユーザーからのメッセージ
    # @param plan [Plan] 現在編集中のプラン（コンテキスト用）
    # @return [String] AIからの応答テキスト
    def chat(message, plan: nil)
      return error_response("API設定エラー") unless api_key_configured?

      response = call_api(message, plan: plan)
      parse_response(response)
    rescue Faraday::Error => e
      Rails.logger.error "[AiChatService] OpenAI API error: #{e.message}"
      error_response("通信エラーが発生しました")
    rescue StandardError => e
      Rails.logger.error "[AiChatService] Unexpected error: #{e.class} - #{e.message}"
      error_response("エラーが発生しました")
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    def call_api(message, plan:)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          messages: build_messages(message, plan: plan)
        }
      )
    end

    def build_messages(message, plan:)
      messages = [ { role: "system", content: system_prompt(plan) } ]
      messages << { role: "user", content: message }
      messages
    end

    def system_prompt(_plan)
      <<~PROMPT
        あなたはドライブプランのAIアシスタントです。
        ユーザーの要望に応じて、おすすめのスポットやドライブルートを提案してください。

        - 簡潔で親しみやすい口調で回答
        - 具体的なスポット名を挙げる
        - スポットの種類に応じた滞在時間を想定する（軽い立ち寄り30分、食事や観光1〜2時間）
        - 日帰りは往復移動＋滞在で7〜10時間を目安にする
        - まとめは不要。スポット紹介後は「気になるスポットがあれば教えてください！」で締める
      PROMPT
    end

    def parse_response(response)
      return error_response("応答を取得できませんでした") if response.nil?

      content = response.dig("choices", 0, "message", "content")
      return error_response("応答を取得できませんでした") if content.blank?

      content.strip
    end

    def error_response(message)
      "申し訳ありません。#{message}。しばらく経ってからもう一度お試しください。"
    end
  end
end
