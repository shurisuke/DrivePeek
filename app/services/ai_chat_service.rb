# OpenAI API を使用してドライブプランの提案を行う
#
# 使い方:
#   result = AiChatService.chat(message, plan: plan, history: history)
#   # => { message: "栃木の...", spots: [{name: "大谷資料館", ...}] }
#
class AiChatService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  class << self
    # @param message [String] ユーザーからのメッセージ
    # @param plan [Plan] 現在編集中のプラン（コンテキスト用）
    # @param history [Array<AiChatMessage>] 会話履歴
    # @param mode [String] "plan" or "spot"
    # @return [Hash] { message: String, spots: Array }
    def chat(message, plan: nil, history: [], mode: "plan")
      return error_response("API設定エラー") unless api_key_configured?

      response = call_api(message, plan: plan, history: history, mode: mode)
      parse_response(response)
    rescue Faraday::Error
      error_response("通信エラーが発生しました")
    rescue JSON::ParserError
      error_response("応答の解析に失敗しました")
    rescue StandardError
      error_response("エラーが発生しました")
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    def call_api(message, plan:, history:, mode:)
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

      client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          response_format: { type: "json_object" },
          messages: build_messages(plan: plan, history: history, mode: mode)
        }
      )
    end

    def build_messages(plan:, history:, mode:)
      messages = [ { role: "system", content: system_prompt(plan, mode) } ]

      # 履歴を追加（既に最新のユーザーメッセージを含む）
      history.each do |msg|
        messages << { role: msg.role, content: msg.content }
      end

      messages
    end

    def system_prompt(_plan, mode)
      base_prompt + (mode == "spot" ? spot_mode_prompt : plan_mode_prompt)
    end

    def base_prompt
      <<~PROMPT
        あなたはドライブプランのAIアシスタントです。

        【回答ルール】
        - 必ず以下のJSON形式で回答すること
        - 簡潔で親しみやすい口調
        - スポット提案時は具体的な名前と住所を含める

        【注意】
        - スポット提案がない会話（挨拶など）では spots を空配列 [] にする
        - 住所は「都道府県市区町村番地」の形式で正確に記載
      PROMPT
    end

    def plan_mode_prompt
      <<~PROMPT

        【プラン提案モード】
        あなたの役割はドライブプラン全体を提案することです。
        - ユーザーの出発地・目的エリア・所要時間を考慮
        - 3〜5件のスポットをルート順に提案
        - スポット間の移動を考慮した効率的な順序で提案
        - message でルート全体の魅力や所要時間の目安を説明
        - 最後は「このプランはいかがですか？調整したい点があればお聞かせください！」で締める

        【JSON形式】
        {
          "message": "プラン全体の説明（マークダウン可）",
          "spots": [
            {"name": "スポット名", "address": "都道府県から始まる住所", "reason": "おすすめ理由（1文）"}
          ]
        }
      PROMPT
    end

    def spot_mode_prompt
      current_month = Time.current.month
      <<~PROMPT

        【スポット提案モード - 重要】
        あなたの役割は「観光」の観点で個別のスポットを深掘りして提案することです。
        ★ 必ず具体的な施設・店舗・名所を提案すること（広域地名はNG）★

        【現在の時期】
        #{current_month}月です。スポットを紹介する際は、この時期ならではの楽しみ方があれば触れてください。

        ★★★ 絶対に守ること ★★★
        - spots 配列は【必ず3件】にすること
        - 各スポットを深掘りして紹介する

        【JSON形式】
        {
          "intro": "導入文（ユーザーの要望に応じた1文。例: 〇〇で絶景を楽しめるスポットをご紹介しますね！）",
          "spots": [
            {
              "name": "スポット名",
              "address": "都道府県から始まる住所",
              "description": "詳細説明（4〜6文）"
            }
          ],
          "closing": "締めの一言（例: 他に気になるジャンルやエリアがあれば教えてください！）"
        }

        description の書き方:
        - 1文目: そのスポットの魅力を端的に表す要約文（例: 「〇〇は、△△が楽しめる人気スポットです。」）
        - 2文目以降: 見どころ・過ごし方・訪問時間帯・滞在目安・写真映えポイントなど

        トーン:
        - 実際に行ったことがあるかのような臨場感
        - 「ここでしか味わえない」「必見」など感情を込めた表現
      PROMPT
    end

    def parse_response(response)
      return error_response("応答を取得できませんでした") if response.nil?

      content = response.dig("choices", 0, "message", "content")
      return error_response("応答を取得できませんでした") if content.blank?

      parsed = JSON.parse(content, symbolize_names: true)
      {
        message: parsed[:message] || "",
        intro: parsed[:intro] || "",
        spots: parsed[:spots] || [],
        closing: parsed[:closing] || ""
      }
    end

    def error_response(message)
      {
        message: "申し訳ありません。#{message}。しばらく経ってからもう一度お試しください。",
        spots: [],
        closing: ""
      }
    end
  end
end
