# frozen_string_literal: true

require "rails_helper"

RSpec.describe Openai do
  describe ".configured?" do
    context "OPENAI_API_KEYが設定されている場合" do
      it "trueを返す" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return("test-key")

        expect(Openai.configured?).to be true
      end
    end

    context "OPENAI_API_KEYが設定されていない場合" do
      it "falseを返す" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("OPENAI_API_KEY").and_return(nil)

        expect(Openai.configured?).to be false
      end
    end
  end

  describe ".chat" do
    let(:mock_client) { instance_double(OpenAI::Client) }
    let(:messages) { [ { role: "user", content: "Hello" } ] }
    let(:api_response) do
      {
        "choices" => [
          { "message" => { "content" => "Hi there!" } }
        ]
      }
    end

    before do
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
      allow(mock_client).to receive(:chat).and_return(api_response)
    end

    it "OpenAI::Clientにパラメータを渡して呼び出す" do
      Openai.chat(messages: messages)

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(
          model: "gpt-4o-mini",
          max_tokens: 1024,
          messages: messages
        )
      )
    end

    it "デフォルトモデルを使用する" do
      expect(Openai::DEFAULT_MODEL).to eq("gpt-4o-mini")
    end

    it "カスタムモデルを指定できる" do
      Openai.chat(messages: messages, model: "gpt-4o")

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(model: "gpt-4o")
      )
    end

    it "max_tokensを指定できる" do
      Openai.chat(messages: messages, max_tokens: 2048)

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(max_tokens: 2048)
      )
    end

    it "追加オプションを渡せる" do
      Openai.chat(messages: messages, response_format: { type: "json_object" })

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(response_format: { type: "json_object" })
      )
    end

    it "APIレスポンスを返す" do
      result = Openai.chat(messages: messages)

      expect(result).to eq(api_response)
    end
  end
end
