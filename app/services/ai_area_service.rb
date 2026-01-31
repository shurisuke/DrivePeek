# エリア選択によるAI提案機能
#
# 円内スポット検索と、ジャンル指定によるAI提案を行う
#
class AiAreaService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  # 緯度1度 ≈ 111km、経度1度 ≈ 91km（日本の緯度で概算）
  LAT_KM = 111.0
  LNG_KM = 91.0

  # 季節ガイド（ドライブの雰囲気づくり + 避けるべきもの）
  SEASON_GUIDE = {
    1 => "冬（冬景色や温泉が楽しめる。海や夏向けスポットは避ける）",
    2 => "冬（冬景色や温泉が楽しめる。海や夏向けスポットは避ける）",
    3 => "早春（春の訪れを感じるドライブ。まだ寒いので温泉も◎）",
    4 => "春（桜や花を楽しむ最高の季節。自然散策や屋外スポットが◎）",
    5 => "初夏（新緑が美しい季節。自然スポットや屋外が気持ちいい）",
    6 => "梅雨（雨でも楽しめる施設やグルメがおすすめ。見晴らしスポットは天気次第）",
    7 => "夏（水辺や高原で涼を求めるドライブ。炎天下の屋外散策は避ける）",
    8 => "夏（避暑地や水辺が人気。暑さ対策できる場所を選びたい）",
    9 => "初秋（まだ暑いが秋の気配。涼しい高原や秋の味覚が◎）",
    10 => "秋（紅葉が始まり景色が美しい。温泉との組み合わせが◎）",
    11 => "晩秋（紅葉見頃で絶景ドライブに最適。温泉との組み合わせが◎）",
    12 => "冬（冬景色や温泉が楽しめる。海や夏向けスポットは避ける）"
  }.freeze

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

      # モードに応じて候補スポットを取得
      case mode
      when "plan"
        slot_data = fetch_slot_candidates(center_lat, center_lng, radius_km, slots)
        all_spots = slot_data.flat_map { |slot| slot[:candidates] }
        slot_sizes = slot_data.map { |slot| slot[:candidates].size }
      when "spots"
        genre = Genre.find_by(id: genre_id)
        return error_response("ジャンルが見つかりません", mode: mode) unless genre
        all_spots = fetch_genre_candidates(center_lat, center_lng, radius_km, genre, count)
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

      # プロンプト生成 → API呼び出し → 選出
      prompt = case mode
               when "plan"
                 build_plan_mode_prompt(radius_km, slot_data)
               when "spots"
                 build_spot_mode_prompt(radius_km, genre, all_spots)
               end
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

    # 円内のスポットを取得するスコープ
    def spots_in_circle(center_lat, center_lng, radius_km)
      # 簡易距離計算: SQRT(POW((lat - center) * 111, 2) + POW((lng - center) * 91, 2))
      distance_sql = <<~SQL.squish
        SQRT(
          POW((lat - ?) * #{LAT_KM}, 2) +
          POW((lng - ?) * #{LNG_KM}, 2)
        )
      SQL

      Spot
        .where("#{distance_sql} <= ?", center_lat, center_lng, radius_km)
        .includes(:genres)
    end

    # 各スロットに対して候補スポットを取得（人気順10件）
    # @return [Array<Hash>] [{ genre_name:, candidates: [spot_hash, ...] }, ...]
    def fetch_slot_candidates(center_lat, center_lng, radius_km, slots)
      slot_candidates = []

      slots.each do |slot|
        genre_id = slot[:genre_id] || slot["genre_id"]
        genre = Genre.find_by(id: genre_id)
        next unless genre

        spots = spots_in_circle(center_lat, center_lng, radius_km)
        spots = spots.filter_by_genres([genre_id])

        # お気に入り数上位10件を候補として取得
        top_spot_ids = spots
          .left_joins(:like_spots)
          .group(:id)
          .order("COUNT(like_spots.id) DESC")
          .limit(10)
          .pluck(:id)

        candidates = Spot.includes(:genres).where(id: top_spot_ids).map { |s| spot_to_hash(s) }

        slot_candidates << {
          genre_name: genre.name,
          candidates: candidates
        }
      end

      slot_candidates
    end

    # スポットモード用: 人気スポットを取得（人気順N件）
    # @return [Array<Hash>] [spot_hash, ...]
    def fetch_genre_candidates(center_lat, center_lng, radius_km, genre, count)
      # まず円内+ジャンルでスポットIDを取得（DISTINCTを回避）
      candidate_ids = spots_in_circle(center_lat, center_lng, radius_km)
        .filter_by_genres([genre.id])
        .pluck(:id)

      return [] if candidate_ids.empty?

      # お気に入り数でソートして上位N件を取得（人気スポットとして確定）
      top_spot_ids = Spot
        .where(id: candidate_ids)
        .left_joins(:like_spots)
        .group(:id)
        .order("COUNT(like_spots.id) DESC")
        .limit(count)
        .pluck(:id)

      Spot.includes(:genres).where(id: top_spot_ids).map { |spot| spot_to_hash(spot) }
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

    # OpenAI API呼び出し（純粋なAPI通信のみ）
    # @return [Hash] パース済みJSONレスポンス
    def call_openai_api(prompt)
      response = openai_client.chat(
        parameters: {
          model: MODEL,
          max_tokens: MAX_TOKENS,
          response_format: { type: "json_object" },
          messages: [{ role: "system", content: prompt }]
        }
      )

      content = response.dig("choices", 0, "message", "content")
      return {} if content.blank?

      JSON.parse(content, symbolize_names: true)
    end

    # プランモード: AIレスポンスからスポットを選出
    # @param ai_response [Hash] { picks: [...], theme:, intro:, closing: }
    # @param all_spots [Array<Hash>] 全候補スポット（通し番号順）
    # @param slot_sizes [Array<Integer>] 各スロットの候補数
    # @return [Array<Hash>] 選出されたスポット
    def select_plan_spots(ai_response, all_spots, slot_sizes)
      picks = ai_response[:picks] || []
      selected = picks.map { |n| all_spots[n - 1] }.compact

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

    def build_plan_mode_prompt(radius, slot_candidates)
      month = Time.current.month
      season = SEASON_GUIDE[month]
      area_name = slot_candidates.first&.dig(:candidates)&.first&.dig(:city) || "選択エリア"

      # スロットごとに候補を通し番号で列挙
      index = 1
      slots_info = slot_candidates.map do |slot|
        spots_list = slot[:candidates].map do |s|
          "#{index}.#{s[:name]}".tap { index += 1 }
        end.join(" ")
        "[#{slot[:genre_name]}] #{spots_list}"
      end.join("\n")

      <<~PROMPT
        あなたはドライブプランAIです。

        ■ #{month}月・#{season} / #{area_name}周辺（半径#{radius.round(1)}km）

        ■ 候補スポット
        #{slots_info}

        ■ タスク
        各ジャンルから季節・ドライブに最適な1件を選び、テーマと紹介文を作成。

        ■ JSON
        {"picks":[番号,番号,...],"theme":"テーマ","intro":"紹介文","closing":"ドライブへの期待を高める一言"}
      PROMPT
    end

    def build_spot_mode_prompt(radius, genre, candidates)
      area_name = candidates.first&.dig(:city) || "選択エリア"
      spots_list = candidates.map { |s| s[:name] }.join("、")

      <<~PROMPT
        あなたはドライブスポット紹介AIです。

        ■ #{area_name}周辺（半径#{radius.round(1)}km）
        ■ ジャンル: #{genre.name}

        ■ 人気スポット
        #{spots_list}

        ■ タスク
        上記の人気スポットをシンプルに紹介。

        ■ JSON
        {"intro":"紹介文（1〜2文）","closing":"気になるスポットの追加を促す一言"}
      PROMPT
    end

    # 提案レスポンスを構築
    def build_suggest_response(ai_result, selected_spots, mode = "plan")
      # 導入文を構築（モードで分岐）
      intro = case mode
              when "plan"
                theme = ai_result[:theme] || "おすすめドライブプラン"
                intro_text = ai_result[:intro] || ""
                "#{theme}\n#{intro_text}"
              when "spots"
                ai_result[:intro] || ""
              end

      # spotsを既存形式で構築
      spots_for_response = selected_spots.map do |spot|
        {
          spot_id: spot[:id],
          name: spot[:name],
          address: spot[:address],
          lat: spot[:lat],
          lng: spot[:lng],
          place_id: spot[:place_id]
        }
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
