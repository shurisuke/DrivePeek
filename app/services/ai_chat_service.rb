# OpenAI API を使用してスポットに関する質問に回答する
#
# 「スポットについて質問する」機能専用
# プラン提案機能は AiPlanService に移行予定
#
class AiChatService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  # 季節ガイド（プロンプトで季節感を出すため）
  SEASON_GUIDE = {
    1 => "冬（雪景色、温泉、冬の味覚）",
    2 => "冬（梅の花、温泉、冬の味覚）",
    3 => "早春（梅・早咲き桜、春の訪れ）",
    4 => "春（桜、新緑の始まり、春の花）",
    5 => "初夏（新緑、ツツジ、藤、バラ）",
    6 => "初夏（紫陽花、新緑、梅雨の晴れ間ドライブ）",
    7 => "夏（海、高原の涼、ひまわり、夏祭り）",
    8 => "夏（海、高原避暑、夏野菜、花火）",
    9 => "初秋（彼岸花、コスモス、秋の味覚）",
    10 => "秋（紅葉の始まり、秋桜、秋の味覚）",
    11 => "秋（紅葉見頃、秋の味覚、温泉）",
    12 => "冬（イルミネーション、温泉、冬の味覚）"
  }.freeze

  # スロット種別の日本語表記（条件設定モーダルで使用）
  SLOT_HINTS = {
    sightseeing: { name: "観光名所", hint: "景勝地・公園・神社仏閣など" },
    gourmet: { name: "グルメ", hint: "飲食店・カフェ・道の駅" },
    onsen: { name: "温泉", hint: "温泉・入浴施設・スパ" },
    sea: { name: "海スポット", hint: "海岸・ビーチ・海沿いの施設" },
    nature: { name: "自然", hint: "山・森・自然公園" },
    activity: { name: "アクティビティ", hint: "体験施設・アウトドア・遊び場" },
    cafe: { name: "カフェ", hint: "カフェ・喫茶店・スイーツ店" },
    michinoeki: { name: "道の駅", hint: "道の駅・物産館" },
    shopping: { name: "買い物", hint: "ショッピング施設・お土産店" }
  }.freeze

  class << self
    # スポットに関する質問に回答する
    # @param message [String] ユーザーからの質問
    # @param plan [Plan] 現在編集中のプラン（エリア特定用）
    # @return [Hash] { type:, message:, spots:, closing: }
    def answer(message, plan: nil)
      return error_response("API設定エラー") unless api_key_configured?

      Rails.logger.info "[AiChatService] Answer mode - Message: #{message}"

      # プランからエリア情報を取得（出発地点の都道府県）
      prefecture = extract_prefecture_from_plan(plan)

      # 参考スポットを取得（都道府県が分かれば絞り込み）
      candidates = fetch_reference_spots(prefecture)

      Rails.logger.info "[AiChatService] Reference spots: #{candidates.size}件"

      # AIに質問を投げる
      ai_result = call_answer_ai(candidates, message)

      build_answer_response(ai_result, candidates)

    rescue Faraday::Error => e
      Rails.logger.error("[AiChatService] Faraday error: #{e.class} - #{e.message}")
      error_response("通信エラーが発生しました")
    rescue JSON::ParserError => e
      Rails.logger.error("[AiChatService] JSON parse error: #{e.message}")
      error_response("応答の解析に失敗しました")
    rescue StandardError => e
      Rails.logger.error("[AiChatService] Unexpected error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      error_response("エラーが発生しました")
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    # プランから都道府県を抽出
    def extract_prefecture_from_plan(plan)
      return nil unless plan&.start_point&.address

      # 住所から都道府県を抽出（例: "茨城県水戸市..." → "茨城県"）
      plan.start_point.address.match(/^(.+?[都道府県])/)&.[](1)
    end

    # 参考スポットを取得（質問回答の補助用）
    def fetch_reference_spots(prefecture)
      scope = Spot.all
      scope = scope.where(prefecture: prefecture) if prefecture

      scope
        .includes(:genres)
        .order(Arel.sql("RANDOM()"))
        .limit(20)
        .map { |spot| spot_to_hash(spot) }
    end

    # SpotレコードをHashに変換
    def spot_to_hash(spot)
      {
        id: spot.id,
        name: spot.name,
        address: spot.address,
        prefecture: spot.prefecture,
        city: spot.city,
        lat: spot.lat,
        lng: spot.lng,
        place_id: spot.place_id,
        genres: spot.genres.map(&:name)
      }
    end

    # AIに質問を投げる
    def call_answer_ai(candidates, user_request)
      prompt = build_answer_prompt(candidates, user_request)

      response = openai_client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          response_format: { type: "json_object" },
          messages: [ { role: "system", content: prompt } ]
        }
      )

      content = response.dig("choices", 0, "message", "content")
      return {} if content.blank?

      JSON.parse(content, symbolize_names: true)
    end

    # 質問回答用プロンプト
    def build_answer_prompt(candidates, user_request)
      current_month = Time.current.month
      season_info = SEASON_GUIDE[current_month]
      candidates_json = candidates.take(10).map { |c|
        { id: c[:id], name: c[:name], address: c[:address], genres: c[:genres] }
      }.to_json

      <<~PROMPT
        あなたはドライブスポット案内のAIアシスタントです。必ずJSON形式で応答してください。

        【#{current_month}月 - #{season_info}】

        【ユーザーの質問】
        #{user_request}

        【エリアのスポット情報（参考）】
        #{candidates_json}

        【あなたの役割】
        ユーザーの質問に対して、親切で詳しい回答をしてください。
        - 候補スポットの情報を参考にして具体的に答える
        - #{current_month}月の季節感を含める
        - 知識を活かして補足情報も提供する

        【出力JSON】
        {
          "answer": "ユーザーの質問への回答（マークダウン形式OK、3〜5文）",
          "related_spots": [関連するスポットのID（最大3件、空配列OK）],
          "closing": "会話を続けるための一言（例: 他にも気になることがあれば聞いてください）"
        }
      PROMPT
    end

    # 回答レスポンスを構築
    def build_answer_response(ai_result, candidates)
      related_spot_ids = ai_result[:related_spots] || []

      # 関連スポットを構築（最大3件）
      related_spots = related_spot_ids.take(3).map do |id|
        candidate = candidates.find { |c| c[:id] == id }
        next nil unless candidate

        {
          spot_id: candidate[:id],
          name: candidate[:name],
          address: candidate[:address],
          lat: candidate[:lat],
          lng: candidate[:lng],
          place_id: candidate[:place_id]
        }
      end.compact

      {
        type: "answer",
        message: ai_result[:answer] || "",
        spots: related_spots,
        closing: ai_result[:closing] || ""
      }
    end

    def openai_client
      @openai_client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    end

    def error_response(message)
      {
        type: "conversation",
        message: "申し訳ありません。#{message}。しばらく経ってからもう一度お試しください。",
        spots: [],
        closing: ""
      }
    end
  end
end
