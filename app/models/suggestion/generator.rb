# frozen_string_literal: true

# エリア選択による提案機能
#
# 円内スポット検索と、ジャンル指定による提案を行う
# スポット検索は Suggestion::SpotFinder、プロンプト生成は Suggestion::PromptBuilder に委譲
#
class Suggestion::Generator
  MAX_TOKENS = 1024

  class << self
    # 提案を生成
    # @param plan [Plan] 対象プラン
    # @param center_lat [Float] 中心緯度
    # @param center_lng [Float] 中心経度
    # @param radius_km [Float] 半径（km）
    # @param slots [Array<Hash>] [{ genre_id: 5 }, ...] スロットごとのジャンル指定
    # @return [Hash] { type:, message:, spots:, closing: }
    def generate(plan:, center_lat:, center_lng:, radius_km:, slots: [], priority_genre_ids: [])
      return error_response("API設定エラー") unless Openai.configured?

      finder = Suggestion::SpotFinder.new(center_lat, center_lng, radius_km)

      # スロットごとに候補スポットを取得
      slot_data = finder.fetch_for_slots(slots, priority_genre_ids: priority_genre_ids)
      all_spots = slot_data.flat_map { |slot| slot[:candidates] }
      slot_sizes = slot_data.map { |slot| slot[:candidates].size }
      prompt = Suggestion::PromptBuilder.plan_mode(slot_data, radius_km)

      if all_spots.empty?
        return {
          type: "plan",
          message: "指定されたエリア・ジャンルでスポットが見つかりませんでした。条件を変更してお試しください。",
          spots: [],
          closing: ""
        }
      end

      # API呼び出し → 選出
      ai_response = call_openai_api(prompt)
      selected_spots = select_plan_spots(ai_response, all_spots, slot_sizes)

      build_suggest_response(ai_response, selected_spots)

    rescue Faraday::Error => e
      Rails.logger.error("[Suggestion::Generator] Faraday error: #{e.class} - #{e.message}")
      error_response("通信エラーが発生しました")
    rescue JSON::ParserError => e
      Rails.logger.error("[Suggestion::Generator] JSON parse error: #{e.message}")
      error_response("応答の解析に失敗しました")
    rescue StandardError => e
      Rails.logger.error("[Suggestion::Generator] Unexpected error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      error_response("エラーが発生しました")
    end

    private

    # OpenAI API呼び出し（純粋なAPI通信のみ）
    # @return [Hash] パース済みJSONレスポンス
    def call_openai_api(prompt)
      response = Openai.chat(
        messages: [ { role: "system", content: prompt } ],
        max_tokens: MAX_TOKENS,
        response_format: { type: "json_object" }
      )

      content = response.dig("choices", 0, "message", "content")
      return {} if content.blank?

      JSON.parse(content, symbolize_names: true)
    end

    # プランモード: レスポンスからスポットを選出
    # @param ai_response [Hash] { picks: [{n:, d:}, ...], intro:, closing: }
    # @param all_spots [Array<Hash>] 全候補スポット（通し番号順）
    # @param slot_sizes [Array<Integer>] 各スロットの候補数
    # @return [Array<Hash>] 選出されたスポット（descriptionを含む）
    def select_plan_spots(ai_response, all_spots, slot_sizes)
      picks = ai_response[:picks] || []
      slot_count = slot_sizes.size

      # 各スロットの開始インデックスを計算
      slot_offsets = []
      offset = 0
      slot_sizes.each do |size|
        slot_offsets << offset
        offset += size
      end

      # AIが選んだスポットを取得（どのスロットから選ばれたかも記録）
      selected = []
      selected_slot_indices = Set.new

      picks.first(slot_count).each do |pick|
        number = pick[:n]
        description = pick[:d]
        spot = all_spots[number - 1]
        next unless spot

        # このスポットがどのスロットに属するか特定
        slot_index = slot_offsets.rindex { |o| number > o }
        next if slot_index.nil? || selected_slot_indices.include?(slot_index)

        selected_slot_indices.add(slot_index)
        selected << spot.merge(description: description)
      end

      # フォールバック: 選出がないスロットは人気1位で補完
      if selected.size < slot_count
        slot_sizes.each_with_index do |size, i|
          next if selected_slot_indices.include?(i) || size == 0

          fallback_spot = all_spots[slot_offsets[i]]
          selected << fallback_spot if fallback_spot
        end
      end

      selected
    end

    # 提案レスポンスを構築
    def build_suggest_response(ai_result, selected_spots)
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
        type: "plan",
        intro: intro,
        spots: spots_for_response,
        closing: ai_result[:closing] || "気になるスポットがあればプランに追加してください！"
      }
    end

    def error_response(message)
      {
        type: "error",
        message: "申し訳ありません。#{message}。しばらく経ってからもう一度お試しください。",
        spots: [],
        closing: ""
      }
    end
  end
end
