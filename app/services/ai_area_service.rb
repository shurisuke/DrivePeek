# エリア選択によるAI提案機能
#
# 円内スポット検索と、ジャンル指定によるAI提案を行う
# スポット検索は AiArea::SpotFinder、プロンプト生成は AiArea::PromptBuilder に委譲
#
class AiAreaService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  class << self
    # AI提案を生成
    # @param plan [Plan] 対象プラン
    # @param center_lat [Float] 中心緯度
    # @param center_lng [Float] 中心経度
    # @param radius_km [Float] 半径（km）
    # @param slots [Array<Hash>] [{ genre_id: 5 }, ...] プランモード用
    # @param mode [String] "plan" | "spots"
    # @param genre_id [Integer] スポットモード用ジャンルID
    # @param count [Integer] スポットモード用件数
    # @return [Hash] { type:, message:, spots:, closing: }
    def generate(plan:, center_lat:, center_lng:, radius_km:, slots: [], mode: "plan", genre_id: nil, count: nil)
      return error_response("API設定エラー", mode: mode) unless api_key_configured?

      finder = AiArea::SpotFinder.new(center_lat, center_lng, radius_km)

      # モードに応じて候補スポットを取得
      case mode
      when "plan"
        slot_data = finder.fetch_for_slots(slots)
        all_spots = slot_data.flat_map { |slot| slot[:candidates] }
        slot_sizes = slot_data.map { |slot| slot[:candidates].size }
        prompt = AiArea::PromptBuilder.plan_mode(slot_data, radius_km)
      when "spots"
        genre = Genre.find_by(id: genre_id)
        return error_response("ジャンルが見つかりません", mode: mode) unless genre
        all_spots = finder.fetch_for_genre(genre, count)
        prompt = AiArea::PromptBuilder.spot_mode(all_spots, genre, radius_km)
      else
        return error_response("不正なモードです", mode: nil)
      end

      if all_spots.empty?
        return {
          type: mode,
          message: "指定されたエリア・ジャンルでスポットが見つかりませんでした。条件を変更してお試しください。",
          spots: [],
          closing: ""
        }
      end

      # API呼び出し → 選出
      ai_response = call_openai_api(prompt)
      selected_spots = case mode
      when "plan"
                         select_plan_spots(ai_response, all_spots, slot_sizes)
      when "spots"
                         all_spots
      end

      build_suggest_response(ai_response, selected_spots, mode)

    rescue Faraday::Error => e
      Rails.logger.error("[AiAreaService] Faraday error: #{e.class} - #{e.message}")
      error_response("通信エラーが発生しました", mode: mode)
    rescue JSON::ParserError => e
      Rails.logger.error("[AiAreaService] JSON parse error: #{e.message}")
      error_response("応答の解析に失敗しました", mode: mode)
    rescue StandardError => e
      Rails.logger.error("[AiAreaService] Unexpected error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      error_response("エラーが発生しました", mode: mode)
    end

    private

    def api_key_configured?
      ENV["OPENAI_API_KEY"].present?
    end

    # OpenAI API呼び出し（純粋なAPI通信のみ）
    # @return [Hash] パース済みJSONレスポンス
    def call_openai_api(prompt)
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

    # プランモード: AIレスポンスからスポットを選出
    # @param ai_response [Hash] { picks: [{n:, d:}, ...], intro:, closing: }
    # @param all_spots [Array<Hash>] 全候補スポット（通し番号順）
    # @param slot_sizes [Array<Integer>] 各スロットの候補数
    # @return [Array<Hash>] 選出されたスポット（descriptionを含む）
    def select_plan_spots(ai_response, all_spots, slot_sizes)
      picks = ai_response[:picks] || []

      selected = picks.filter_map do |pick|
        number = pick[:n]
        description = pick[:d]
        spot = all_spots[number - 1]
        next unless spot

        spot.merge(description: description)
      end

      # フォールバック: 選出がない場合は各スロットの人気1位を採用
      return selected if selected.any?

      fallback_for_plan(all_spots, slot_sizes)
    end

    # プランモードのフォールバック: 各スロットの人気1位を採用
    def fallback_for_plan(all_spots, slot_sizes)
      result = []
      offset = 0
      slot_sizes.each do |size|
        result << all_spots[offset] if size > 0
        offset += size
      end
      result.compact
    end

    # 提案レスポンスを構築
    def build_suggest_response(ai_result, selected_spots, mode = "plan")
      intro = ai_result[:intro] || ""

      spots_for_response = selected_spots.map do |spot|
        {
          spot_id: spot[:id],
          name: spot[:name],
          address: spot[:address],
          lat: spot[:lat],
          lng: spot[:lng],
          place_id: spot[:place_id],
          description: spot[:description]
        }.compact
      end

      {
        type: mode,
        intro: intro,
        spots: spots_for_response,
        closing: ai_result[:closing] || "気になるスポットがあればプランに追加してください！"
      }
    end

    def openai_client
      @openai_client ||= OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
    end

    def error_response(message, mode: nil)
      {
        type: mode || "error",
        message: "申し訳ありません。#{message}。しばらく経ってからもう一度お試しください。",
        spots: [],
        closing: ""
      }
    end
  end
end
