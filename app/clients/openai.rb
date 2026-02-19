# frozen_string_literal: true

# 責務: OpenAI API との通信を提供する
#
# 提供メソッド:
#   - configured?: APIキーが設定されているか確認
#   - chat: Chat Completion API を呼び出す
#
module Openai
  DEFAULT_MODEL = "gpt-4o-mini"

  class << self
    # APIキーが設定されているか確認
    # @return [Boolean]
    def configured?
      api_key.present?
    end

    # Chat Completion API を呼び出す
    # @param messages [Array<Hash>] メッセージ配列
    # @param model [String] モデル名
    # @param max_tokens [Integer] 最大トークン数
    # @param options [Hash] その他のオプション（response_format など）
    # @return [Hash] APIレスポンス
    def chat(messages:, model: DEFAULT_MODEL, max_tokens: 1024, **options)
      client.chat(
        parameters: {
          model: model,
          max_tokens: max_tokens,
          messages: messages,
          **options
        }
      )
    end

    private

    def client
      OpenAI::Client.new(access_token: api_key)
    end

    def api_key
      ENV["OPENAI_API_KEY"]
    end
  end
end
