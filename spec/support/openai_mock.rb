# frozen_string_literal: true

module ApiMocks
  module OpenAI
    def stub_openai_chat(response_content:)
      response = {
        "id" => "chatcmpl-test123",
        "object" => "chat.completion",
        "created" => Time.current.to_i,
        "model" => "gpt-4o-mini",
        "choices" => [ {
          "index" => 0,
          "message" => {
            "role" => "assistant",
            "content" => response_content
          },
          "finish_reason" => "stop"
        } ],
        "usage" => {
          "prompt_tokens" => 100,
          "completion_tokens" => 50,
          "total_tokens" => 150
        }
      }

      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: 200, body: response.to_json, headers: { "Content-Type" => "application/json" })
    end

    def stub_openai_plan_response(spots:, theme: "テストテーマ")
      content = {
        theme: theme,
        description: "テスト説明文です。",
        spot_ids: spots.map(&:id),
        spot_descriptions: spots.each_with_object({}) { |s, h| h[s.id.to_s] = "#{s.name}の説明" },
        closing: "楽しいドライブを！"
      }.to_json

      stub_openai_chat(response_content: content)
    end

    def stub_openai_spots_response(spots:)
      content = {
        spots: spots.map { |s| { spot_id: s.id, description: "#{s.name}の説明" } },
        message: "おすすめのスポットです。"
      }.to_json

      stub_openai_chat(response_content: content)
    end

    def stub_openai_conversation_response(message:)
      content = {
        message: message
      }.to_json

      stub_openai_chat(response_content: content)
    end

    def stub_openai_genre_detection(slugs:)
      stub_openai_chat(response_content: slugs.join(", "))
    end

    def stub_openai_error(status: 500, message: "Internal Server Error")
      stub_request(:post, "https://api.openai.com/v1/chat/completions")
        .to_return(status: status, body: { error: { message: message } }.to_json)
    end

    # 汎用スタブ（デフォルトのJSON応答）
    def stub_openai_chat_api
      stub_openai_chat(response_content: {
        theme: "テストテーマ",
        description: "テスト説明",
        spot_ids: [],
        spot_descriptions: {},
        closing: "楽しんでください"
      }.to_json)
    end

    # カスタムレスポンスでスタブ
    def stub_openai_chat_api_with_response(response_hash)
      stub_openai_chat(response_content: response_hash.to_json)
    end
  end
end

RSpec.configure do |config|
  config.include ApiMocks::OpenAI
end
