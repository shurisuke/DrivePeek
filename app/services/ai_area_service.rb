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
    def suggest(plan:, center_lat:, center_lng:, radius_km:, slots: [], mode: "plan", genre_id: nil, count: nil)
      return error_response("API設定エラー", mode: mode) unless api_key_configured?

      # モードに応じてスポット選定
      case mode
      when "plan"
        selected_spots = select_spots_for_slots(center_lat, center_lng, radius_km, slots)
      when "spots"
        genre = Genre.find_by(id: genre_id)
        return error_response("ジャンルが見つかりません", mode: mode) unless genre
        selected_spots = select_spots_for_genre(center_lat, center_lng, radius_km, genre, count)
      else
        return error_response("不正なモードです", mode: nil)
      end

      if selected_spots.empty?
        return {
          type: mode,
          message: "指定されたエリア・ジャンルでスポットが見つかりませんでした。条件を変更してお試しください。",
          spots: [],
          closing: ""
        }
      end

      # AIでテーマと説明文を生成
      ai_result = call_suggest_ai(selected_spots, radius_km, mode, mode == "spots" ? genre : nil)

      build_suggest_response(ai_result, selected_spots, mode)

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

    # 各スロットに対してスポットを選定
    # お気に入り数上位10件からランダムに選ぶ
    def select_spots_for_slots(center_lat, center_lng, radius_km, slots)
      used_ids = []
      selected = []

      slots.each do |slot|
        genre_id = slot[:genre_id] || slot["genre_id"]
        spots = spots_in_circle(center_lat, center_lng, radius_km)
        spots = spots.filter_by_genres([genre_id]) if genre_id.present?
        spots = spots.where.not(id: used_ids) if used_ids.any?

        # お気に入り数上位10件からランダムに選択
        top_spot_ids = spots
          .left_joins(:like_spots)
          .group(:id)
          .order("COUNT(like_spots.id) DESC")
          .limit(10)
          .pluck(:id)

        spot = Spot.includes(:genres).find_by(id: top_spot_ids.sample)
        next unless spot

        used_ids << spot.id
        selected << spot_to_hash(spot)
      end

      selected
    end

    # スポットモード用: 単一ジャンルで複数件選定
    def select_spots_for_genre(center_lat, center_lng, radius_km, genre, count)
      # まず円内+ジャンルでスポットIDを取得（DISTINCTを回避）
      candidate_ids = spots_in_circle(center_lat, center_lng, radius_km)
        .filter_by_genres([genre.id])
        .pluck(:id)

      return [] if candidate_ids.empty?

      # 次にお気に入り数でソートして上位30件を取得
      top_spot_ids = Spot
        .where(id: candidate_ids)
        .left_joins(:like_spots)
        .group(:id)
        .order("COUNT(like_spots.id) DESC")
        .limit(30)
        .pluck(:id)

      selected_ids = top_spot_ids.sample([count, top_spot_ids.size].min)
      spots = Spot.includes(:genres).where(id: selected_ids)

      spots.map { |spot| spot_to_hash(spot) }
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

    # AIにテーマ生成を依頼
    def call_suggest_ai(spots, radius_km, mode = "plan", genre = nil)
      prompt = build_suggest_prompt(spots, radius_km, mode, genre)

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

    # 提案用プロンプト
    def build_suggest_prompt(spots, radius_km, mode, genre)
      current_month = Time.current.month
      season_info = SEASON_GUIDE[current_month]
      area_name = spots.first&.dig(:city) || "選択エリア"

      spots_info = spots.map.with_index(1) do |s, i|
        "#{i}. #{s[:name]}（#{s[:genres].join('、')}）- #{s[:city]}"
      end.join("\n")

      case mode
      when "plan"
        build_plan_mode_prompt(current_month, season_info, area_name, radius_km, spots_info)
      when "spots"
        build_spot_mode_prompt(current_month, season_info, area_name, radius_km, genre, spots_info)
      end
    end

    def build_plan_mode_prompt(month, season, area, radius, spots_info)
      <<~PROMPT
        あなたはドライブプラン提案のAIアシスタントです。必ずJSON形式で応答してください。

        【#{month}月 - #{season}】

        【選択エリア】
        #{area}周辺（半径#{radius.round(1)}km）

        【選定されたスポット】
        #{spots_info}

        【あなたの役割】
        上記のスポットを巡るドライブプランのテーマと紹介文を考えてください。

        【出力JSON】
        {
          "theme": "プランのテーマ（例: 那須高原で自然と温泉を満喫）",
          "introduction": "プラン全体の紹介文（1〜2文、#{month}月の季節感を含める）",
          "closing": "締めの一言"
        }
      PROMPT
    end

    def build_spot_mode_prompt(month, season, area, radius, genre, spots_info)
      <<~PROMPT
        あなたはドライブスポット提案のAIアシスタントです。必ずJSON形式で応答してください。

        【#{month}月 - #{season}】

        【選択エリア】
        #{area}周辺（半径#{radius.round(1)}km）

        【ジャンル】#{genre.name}

        【選定されたスポット】
        #{spots_info}

        【あなたの役割】
        上記の#{genre.name}スポットの紹介文を考えてください。

        【出力JSON】
        {
          "introduction": "#{genre.name}スポットの紹介文（1〜2文、#{month}月の季節感を含める）",
          "closing": "締めの一言"
        }
      PROMPT
    end

    # 提案レスポンスを構築
    def build_suggest_response(ai_result, selected_spots, mode = "plan")
      # 導入文を構築（モードで分岐）
      intro = case mode
              when "plan"
                theme = ai_result[:theme] || "おすすめドライブプラン"
                introduction = ai_result[:introduction] || ""
                "#{theme}\n#{introduction}"
              when "spots"
                ai_result[:introduction] || ""
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
