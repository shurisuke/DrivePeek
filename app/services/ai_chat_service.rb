# OpenAI API を使用してドライブプランの提案を行う
#
# 会話型設計:
#   1. ユーザーメッセージから場所と希望ジャンルを抽出
#   2. 場所が不明ならAIが聞き返す
#   3. 希望ジャンルに基づいて動的に枠を構成
#   4. DBからスポット取得 → AIがプラン提案
#
class AiChatService
  MODEL = "gpt-4o-mini".freeze
  MAX_TOKENS = 1024

  # 場所以外のキーワード（誤マッチ防止）
  NON_LOCATION_WORDS = %w[
    温泉 ドライブ グルメ 観光 自然 絶景 カフェ ランチ 食事
    したい 行きたい 巡りたい 楽しみたい 満喫 堪能
  ].freeze

  # 希望ジャンルのマッピング（キーワード → ジャンル）
  # 優先度: グルメ(1) > 温泉(2) > 観光名所(3)
  WISH_KEYWORDS = {
    # グルメ系（優先度1 - 最も残りやすい）
    "グルメ" => :gourmet, "ランチ" => :gourmet, "食事" => :gourmet,
    "美味しい" => :gourmet, "食べ" => :gourmet, "ご飯" => :gourmet,
    "カフェ" => :cafe, "スイーツ" => :cafe, "甘い" => :cafe,
    # 温泉系（優先度2）
    "温泉" => :onsen, "お風呂" => :onsen, "スパ" => :onsen,
    "入浴" => :onsen, "湯" => :onsen,
    # 観光名所系（優先度3 - 最も入れ替えやすい）
    "観光" => :sightseeing, "名所" => :sightseeing, "絶景" => :sightseeing,
    # 自然系
    "自然" => :nature, "山" => :nature, "森" => :nature, "緑" => :nature,
    "海" => :sea, "ビーチ" => :sea, "海岸" => :sea, "浜" => :sea,
    # アクティビティ系
    "アクティビティ" => :activity, "体験" => :activity, "運動" => :activity,
    "遊び" => :activity, "遊ぶ" => :activity,
    # その他
    "道の駅" => :michinoeki, "買い物" => :shopping, "ショッピング" => :shopping
  }.freeze

  # デフォルトの3枠（優先度順: グルメ > 温泉 > 観光名所）
  DEFAULT_SLOTS = %i[sightseeing gourmet onsen].freeze
  SLOT_PRIORITY = { gourmet: 1, onsen: 2, sightseeing: 3 }.freeze

  class << self
    # @param message [String] ユーザーからのメッセージ（場所 + 希望）
    # @param plan [Plan] 現在編集中のプラン
    # @return [Hash] { type:, message:, spots:, ... }
    def chat(message, plan: nil)
      return error_response("API設定エラー") unless api_key_configured?

      Rails.logger.info "[AiChatService] Message: #{message}"

      # 直前のやり取りを取得（会話継続用）
      previous_context = extract_previous_context(plan)

      # メッセージからエリア情報をDB検索で抽出
      # 直前の会話からエリアを引き継ぐ
      area = find_area_from_message(message) || previous_context&.dig(:area)

      # メッセージから希望ジャンルを抽出してスロット構成
      wishes = extract_wishes(message)
      # 「もう一個」系の場合は直前のスロットに追加
      if add_request?(message) && previous_context&.dig(:slots)
        slots = previous_context[:slots] + wishes.take(1)
      else
        slots = build_slots(wishes, previous_context&.dig(:slots))
      end

      # 部分変更リクエストを検出
      partial_change = detect_partial_change(message, previous_context)

      # レスポンスモードを判定（plan / spots）
      response_mode = detect_response_mode(message)

      Rails.logger.info "[AiChatService] Extracted area: #{area ? "#{area[:keyword]}（#{area[:prefecture]}）" : 'なし'}"
      Rails.logger.info "[AiChatService] Wishes: #{wishes.inspect}, Slots: #{slots.inspect}, Mode: #{response_mode}"
      Rails.logger.info "[AiChatService] Partial change: #{partial_change.inspect}" if partial_change

      # 場所が不明な場合は聞き返す（部分変更の場合はエリア引き継ぎ）
      if area.nil? && partial_change.nil?
        return ask_for_location(message)
      end

      # 出発地点の座標を取得
      start_location = extract_start_location(plan)

      # モードに応じてDB検索方法を切り替え
      candidates = if response_mode == :spots
        # spots モード: エリア中心から30km以内のスポットを取得
        Rails.logger.info "[AiChatService] Spots mode: searching around #{area[:keyword]}"
        search_spots_around_area(area: area)
      else
        # plan モード: 出発地点からの距離でグループ分け
        target_distance = if start_location && area[:lat] && area[:lng]
          calculate_distance(start_location[:lat], start_location[:lng], area[:lat], area[:lng])
        else
          60
        end
        Rails.logger.info "[AiChatService] Plan mode: target=#{target_distance.round(1)}km from start"
        search_spots_from_db(
          prefecture: area[:prefecture],
          start_location: start_location,
          target_distance: target_distance
        )
      end

      Rails.logger.info "[AiChatService] DB candidates (#{candidates.size}件): #{candidates.map { |c| c[:name] }.join(', ')}"

      # スポットが見つからない場合
      if candidates.empty?
        return {
          type: "conversation",
          message: "#{area[:keyword]}エリアでスポットが見つかりませんでした。別のエリアを試してみてください。",
          spots: [],
          closing: ""
        }
      end

      # AIがスポット選定 + 説明文生成
      ai_result = call_ai(
        candidates: candidates,
        user_request: message,
        start_location: start_location,
        previous_context: previous_context,
        slots: slots,
        partial_change: partial_change,
        response_mode: response_mode
      )

      build_final_response(ai_result, candidates, slots, response_mode)

    rescue Faraday::Error => e
      Rails.logger.error("[AiChatService] Faraday error: #{e.class} - #{e.message}")
      Rails.logger.error("[AiChatService] Response body: #{e.response[:body]}") if e.respond_to?(:response) && e.response
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

    # 直前のやり取りを取得（軽量版: 直前1ターンのみ）
    # @return [Hash, nil] { spots:, spot_details:, area:, slots: }
    def extract_previous_context(plan)
      return nil unless plan

      # 「成功した」AI応答（spotsがある）を探す
      # 聞き返し応答（conversation）をスキップして、実際のプラン提案を取得
      successful_assistant = plan.ai_chat_messages
                                 .where(role: "assistant")
                                 .order(created_at: :desc)
                                 .find { |msg| msg.display_spots.any? }
      return nil unless successful_assistant

      spots = successful_assistant.display_spots
      spot_names = spots.map { |s| s[:name] || s["name"] }.compact

      # スポット詳細情報（部分変更用）
      spot_details = spots.map.with_index do |s, i|
        {
          index: i,
          spot_id: s[:spot_id] || s["spot_id"],
          name: s[:name] || s["name"],
          address: s[:address] || s["address"]
        }
      end

      # スポットの住所から都道府県を抽出してエリア情報を構築
      area = extract_area_from_spots(spots)

      # フォールバック: 過去のユーザーメッセージから場所を探す
      unless area
        plan.ai_chat_messages
            .where(role: "user")
            .where("created_at < ?", successful_assistant.created_at)
            .order(created_at: :desc)
            .each do |msg|
              area = find_area_from_message(msg.content)
              break if area
            end
      end

      # 直前の応答で使用したスロット構成を推測（spots数から）
      slots = DEFAULT_SLOTS.take([spot_names.size, 3].max)

      {
        user_message: nil,
        spots: spot_names,
        spot_details: spot_details,
        area: area,
        slots: slots
      }
    end

    # メッセージから希望ジャンルを抽出
    # @return [Array<Symbol>] 抽出されたジャンル（例: [:sea, :onsen]）
    def extract_wishes(message)
      return [] if message.blank?

      wishes = []
      WISH_KEYWORDS.each do |keyword, genre|
        wishes << genre if message.include?(keyword)
      end
      wishes.uniq
    end

    # 「もう一個」「追加して」系のリクエストか判定
    def add_request?(message)
      return false if message.blank?

      add_patterns = %w[もう一個 もう1個 もう一つ もう1つ 追加 増やし 足し]
      add_patterns.any? { |p| message.include?(p) }
    end

    # 部分変更リクエストを検出
    # @return [Hash, nil] { change_indices: [変更する番号], keep_indices: [維持する番号] }
    def detect_partial_change(message, previous_context)
      return nil if message.blank? || previous_context.nil?
      return nil unless previous_context[:spot_details]&.any?

      spot_count = previous_context[:spot_details].size

      # 「〇番（目）だけ変えて」パターン
      if message =~ /(\d)[番目]*.*(?:変え|替え|かえ|チェンジ)/
        change_idx = $1.to_i - 1
        return nil unless change_idx.between?(0, spot_count - 1)
        return {
          change_indices: [change_idx],
          keep_indices: (0...spot_count).to_a - [change_idx]
        }
      end

      # 「温泉だけ変えて」パターン（ジャンル名で指定）
      SLOT_HINTS.each do |slot_type, hint|
        if message.include?(hint[:name]) && message =~ /(?:変え|替え|かえ|チェンジ)/
          # 直前のスロットからそのジャンルのインデックスを探す
          slots = previous_context[:slots] || DEFAULT_SLOTS
          change_idx = slots.index(slot_type)
          next unless change_idx && change_idx < spot_count
          return {
            change_indices: [change_idx],
            keep_indices: (0...spot_count).to_a - [change_idx]
          }
        end
      end

      # 「〇〇以外変えて」パターン
      if message =~ /(.+?)以外.*(?:変え|替え|かえ|チェンジ)/
        keep_name = $1.strip
        # スポット名で一致するものを探す
        keep_idx = previous_context[:spot_details].find_index { |s| s[:name]&.include?(keep_name) }
        if keep_idx
          return {
            change_indices: (0...spot_count).to_a - [keep_idx],
            keep_indices: [keep_idx]
          }
        end
      end

      # 「〇〇は残して」「〇〇はそのままで」パターン
      if message =~ /(.+?)(?:は|だけ)(?:残し|そのまま|キープ)/
        keep_name = $1.strip
        keep_idx = previous_context[:spot_details].find_index { |s| s[:name]&.include?(keep_name) }
        if keep_idx
          # 残す以外を変更
          return {
            change_indices: (0...spot_count).to_a - [keep_idx],
            keep_indices: [keep_idx]
          }
        end
      end

      nil
    end

    # レスポンスモードを判定（plan / spots / answer）
    # 判定優先順: plan > spots > answer > default(plan)
    # @return [Symbol] :plan, :spots, または :answer
    def detect_response_mode(message)
      return :plan if message.blank?

      # 1. プラン提案モード（最優先）
      #    「プラン」「ドライブ」「〜したい」「〜たい」
      if message =~ /プラン|ドライブ|コース|ルート|考えて/
        return :plan
      end
      if message =~ /たい(?:[！!。？?]|\s)*$/
        return :plan
      end

      # 2. スポット提案モード
      #    「〜ない？」「〜ある？」「おすすめ」
      if message =~ /(?:ない|ある)[？?]?\s*$/
        return :spots
      end
      if message =~ /(?:おすすめ|オススメ|お勧め)/
        return :spots
      end

      # 3. 詳細説明モード（感度を鈍く = 厳密なパターンのみ）
      #    「〇〇って何？」「〇〇とは？」のみ
      if message =~ /(?:って何|とは)[？?]\s*$/
        return :answer
      end

      # デフォルトはプラン
      :plan
    end

    # 希望に基づいてスロットを構成
    # 優先度: グルメ(1) > 温泉(2) > 観光名所(3)
    # @param wishes [Array<Symbol>] ユーザーの希望ジャンル
    # @param previous_slots [Array<Symbol>, nil] 直前のスロット構成
    # @return [Array<Symbol>] 構成されたスロット
    def build_slots(wishes, previous_slots = nil)
      # デフォルト3枠から開始
      slots = (previous_slots || DEFAULT_SLOTS).dup

      # 希望がなければデフォルトのまま
      return slots if wishes.empty?

      # 希望を優先度の低いスロットから入れ替え
      # 優先度: グルメ(1) > 温泉(2) > 観光名所(3)
      remaining_wishes = wishes.dup

      # まず、既存スロットと一致する希望を除外（温泉希望で温泉スロットがあれば入れ替え不要）
      remaining_wishes.reject! { |w| slots.include?(w) }

      # 優先度が低いものから入れ替え
      slots_by_priority = slots.sort_by { |s| -(SLOT_PRIORITY[s] || 99) }

      remaining_wishes.each do |wish|
        # 入れ替え対象を探す（優先度が低いものから）
        replaceable = slots_by_priority.find { |s| !remaining_wishes.include?(s) && s != wish }
        if replaceable
          idx = slots.index(replaceable)
          slots[idx] = wish if idx
          slots_by_priority.delete(replaceable)
        else
          # 入れ替え対象がなければ追加（4枠目以降）
          slots << wish
        end
      end

      slots.uniq
    end

    # スポットの住所から都道府県を抽出してエリア情報を構築
    def extract_area_from_spots(spots)
      return nil if spots.empty?

      first_spot = spots.first
      address = (first_spot[:address] || first_spot["address"]).to_s
      return nil if address.blank?

      # 住所から都道府県を抽出（例: "茨城県ひたちなか市..." → "茨城県"）
      prefecture = address.match(/^(.+?[都道府県])/)&.[](1)
      return nil unless prefecture

      # DBから該当県の中心座標を取得
      db_spots = Spot.where(prefecture: prefecture)
      return nil unless db_spots.exists?

      {
        keyword: prefecture.gsub(/[都道府県]$/, ""),
        prefecture: prefecture,
        lat: db_spots.average(:lat).to_f,
        lng: db_spots.average(:lng).to_f
      }
    end

    # メッセージからエリア情報をDB検索で動的に抽出
    # @param message [String] ユーザーメッセージ
    # @return [Hash, nil] { keyword:, prefecture:, lat:, lng: } or nil
    def find_area_from_message(message)
      return nil if message.blank?

      # 場所の接尾辞を除去（「大洗らへん」→「大洗」）
      cleaned = message.gsub(/らへん|あたり|周辺|付近|方面|エリア|地域/, "")

      # 日本語を助詞・記号で分割（の、に、で、を、は、が、と、へ等）
      words = cleaned.gsub(/[のにでをはがとへ、。！？\s]/, " ").split.uniq
      words = words.select { |w| w.length >= 2 }
                   .reject { |w| NON_LOCATION_WORDS.include?(w) }
                   .reject { |w| w =~ /いい|ない|ある|ところ|場所|スポット|とこ/ }
                   .sort_by { |w| -w.length }

      words.each do |word|
        # DBでcity/addressにキーワードを含むスポットを検索
        spots = Spot.where("city LIKE ? OR address LIKE ?", "%#{word}%", "%#{word}%")
        next if spots.empty?

        return {
          keyword: word,
          prefecture: spots.first.prefecture,
          lat: spots.average(:lat).to_f,
          lng: spots.average(:lng).to_f
        }
      end

      nil
    end

    # 場所が不明な場合の応答
    def ask_for_location(message)
      # 希望内容は認識したことを伝えつつ、エリアを聞く
      wish_text = message.present? ? "「#{message}」ですね！" : ""
      {
        type: "conversation",
        message: "#{wish_text}どのエリアでドライブしたいですか？\n\n例: 那須、日光、茨城、箱根、房総など",
        spots: [],
        closing: ""
      }
    end

    # ============================================
    # DBからスポット検索（距離ベースでグループ分け + 人気度考慮）
    # ============================================
    # 距離計算の定数（日本の緯度35°付近）
    KM_PER_LAT = 111  # 緯度1度あたりのkm
    KM_PER_LNG = 91   # 経度1度あたりのkm（緯度35°付近）

    def search_spots_from_db(prefecture:, start_location: nil, target_distance: 60)
      scope = base_spot_scope(prefecture)

      # 出発地点がない場合は全体からサンプリング
      unless start_location
        spots = fetch_spots_with_likes(scope)
        return weighted_sample(spots, 30)
      end

      start_lat = start_location[:lat]
      start_lng = start_location[:lng]

      # 目標距離から動的にレンジを計算
      main_min = target_distance * 0.7
      main_max = target_distance * 1.3
      stopover_min = target_distance * 0.5
      stopover_max = target_distance * 0.8

      # DBレベルで距離計算・フィルタリング
      main_candidates = fetch_spots_by_distance(scope, start_lat, start_lng, main_min, main_max)
      stopover_candidates = fetch_spots_by_distance(scope, start_lat, start_lng, stopover_min, stopover_max)

      # 各グループから人気度を考慮して取得
      selected = []
      selected += weighted_sample(main_candidates, 15)
      selected += weighted_sample(stopover_candidates, 10)

      # 足りなければ補充（全距離範囲で再取得）
      if selected.size < 20
        selected_ids = selected.map { |s| s[:id] }
        fallback = fetch_spots_by_distance(scope, start_lat, start_lng, 0, target_distance * 2)
                     .reject { |s| selected_ids.include?(s[:id]) }
        selected += weighted_sample(fallback, 20 - selected.size)
      end

      Rails.logger.info "[AiChatService] target=#{target_distance.round(1)}km, main(#{main_min.round(0)}-#{main_max.round(0)}km)=#{main_candidates.size}, stopover(#{stopover_min.round(0)}-#{stopover_max.round(0)}km)=#{stopover_candidates.size}"

      selected
    end

    # spotsモード用: エリア中心から一定範囲内のスポットを取得
    # plan モードと違い、出発地点は考慮せずエリア周辺のスポットを返す
    def search_spots_around_area(area:, radius_km: 30)
      scope = base_spot_scope(area[:prefecture])

      # エリア中心座標がない場合は都道府県全体から取得
      unless area[:lat] && area[:lng]
        spots = fetch_spots_with_likes(scope)
        return weighted_sample(spots, 20)
      end

      # エリア中心から radius_km 以内のスポットを取得
      candidates = fetch_spots_by_distance(scope, area[:lat], area[:lng], 0, radius_km)

      # 足りなければ範囲を広げる
      if candidates.size < 10
        candidates = fetch_spots_by_distance(scope, area[:lat], area[:lng], 0, radius_km * 2)
      end

      Rails.logger.info "[AiChatService] Spots around #{area[:keyword]}: #{candidates.size}件 within #{radius_km}km"

      weighted_sample(candidates, 20)
    end

    # 基本スコープ（除外パターン + 都道府県）
    def base_spot_scope(prefecture)
      excluded_patterns = [
        # 宿泊施設
        "%ホテル%", "%旅館%", "%inn%", "%Inn%", "%宿%", "%荘%", "%ペンション%",
        # スーパー・コンビニ
        "%ビッグ%", "%イオン%", "%ヨークベニマル%", "%カワチ%", "%ベイシア%",
        "%セブン%", "%ローソン%", "%ファミリーマート%", "%セブンイレブン%",
        # ガソリンスタンド
        "%エネオス%", "%ENEOS%", "%出光%", "%コスモ%",
        # フィットネスジム
        "%ジム%", "%フィットネス%", "%エニタイム%", "%ANYTIME%", "%ゴールドジム%", "%カーブス%"
      ]

      Spot.where(prefecture: prefecture)
          .where.not(excluded_patterns.map { "spots.name LIKE ?" }.join(" OR "), *excluded_patterns)
    end

    # DBレベルで距離フィルタリング + likes_count取得
    def fetch_spots_by_distance(scope, start_lat, start_lng, min_km, max_km)
      # 距離計算SQL（簡易ユークリッド距離）
      distance_sql = Arel.sql(
        "SQRT(POW((spots.lat - #{start_lat.to_f}) * #{KM_PER_LAT}, 2) + " \
        "POW((spots.lng - #{start_lng.to_f}) * #{KM_PER_LNG}, 2))"
      )

      scope
        .left_joins(:like_spots)
        .group("spots.id")
        .select("spots.*, COUNT(like_spots.id) AS likes_count, #{distance_sql} AS distance_from_start")
        .having("#{distance_sql} BETWEEN ? AND ?", min_km, max_km)
        .includes(:genres)
        .map { |spot| spot_to_hash(spot) }
    end

    # likes_count付きでスポット取得（距離フィルタなし）
    def fetch_spots_with_likes(scope)
      scope
        .left_joins(:like_spots)
        .group("spots.id")
        .select("spots.*, COUNT(like_spots.id) AS likes_count")
        .includes(:genres)
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
        genres: spot.genres.map(&:name),
        likes_count: spot.likes_count.to_i,
        distance_from_start: spot.try(:distance_from_start)&.to_f
      }
    end

    # 人気度（likes_count）を考慮した重み付きサンプリング
    # likes_count が多いほど選ばれやすい（weight = likes_count + 1）
    def weighted_sample(spots, count)
      return spots if spots.size <= count

      selected = []
      remaining = spots.dup

      count.times do
        break if remaining.empty?

        # 重み計算（likes_count + 1 で最低でも1の重みを保証）
        weights = remaining.map { |s| s[:likes_count].to_i + 1 }
        total_weight = weights.sum

        # 重み付きランダム選択
        random_point = rand(total_weight)
        cumulative = 0
        chosen_index = remaining.each_index.find do |i|
          cumulative += weights[i]
          cumulative > random_point
        end

        selected << remaining.delete_at(chosen_index)
      end

      selected
    end

    # 2点間の距離を計算（km）
    def calculate_distance(lat1, lng1, lat2, lng2)
      lat_diff = (lat2 - lat1).abs * 111
      lng_diff = (lng2 - lng1).abs * 91
      Math.sqrt(lat_diff**2 + lng_diff**2)
    end

    def extract_start_location(plan)
      return nil unless plan&.start_point&.lat && plan&.start_point&.lng
      { lat: plan.start_point.lat, lng: plan.start_point.lng, address: plan.start_point.address }
    end

    # ============================================
    # AI呼び出し
    # ============================================
    def call_ai(candidates:, user_request:, start_location: nil, previous_context: nil, slots: nil, partial_change: nil, response_mode: :plan)
      slots ||= DEFAULT_SLOTS

      prompt = case response_mode
               when :answer
                 build_answer_prompt(candidates, user_request)
               when :spots
                 build_spots_prompt(candidates, user_request)
               else
                 build_plan_prompt(candidates, user_request, start_location, previous_context, slots, partial_change)
               end

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

    # スロット種別の日本語表記とヒント
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

    # プランモード用プロンプト（ドライブルート提案）
    def build_plan_prompt(candidates, user_request, start_location = nil, previous_context = nil, slots = nil, partial_change = nil)
      slots ||= DEFAULT_SLOTS
      current_month = Time.current.month
      season_info = SEASON_GUIDE[current_month]
      candidates_json = candidates.map { |c|
        base = { id: c[:id], name: c[:name], address: c[:address], genres: c[:genres] }
        base[:distance_km] = c[:distance_from_start].round(1) if c[:distance_from_start]
        base[:likes] = c[:likes_count] if c[:likes_count].to_i > 0
        base
      }.to_json

      start_location_text = if start_location
        "出発地点: lat=#{start_location[:lat]}, lng=#{start_location[:lng]}（#{start_location[:address]}）"
      else
        "出発地点: 未設定（エリア中心部を想定）"
      end

      # 部分変更の場合の指示を生成
      partial_change_text = ""
      if partial_change && previous_context&.dig(:spot_details)
        keep_spots = partial_change[:keep_indices].map do |idx|
          detail = previous_context[:spot_details][idx]
          "#{idx + 1}番: #{detail[:name]}（ID: #{detail[:spot_id]}）"
        end
        change_slots = partial_change[:change_indices].map { |idx| "#{idx + 1}番" }

        partial_change_text = <<~TEXT

          【★重要★ 部分変更リクエスト】
          以下のスポットは維持してください（spot_idsにそのままIDを含める）：
          #{keep_spots.join("\n")}

          以下の枠だけ新しいスポットを選んでください：
          #{change_slots.join("、")}

        TEXT
      end

      # 直前の会話コンテキスト（あれば）
      previous_text = if previous_context&.dig(:spots)&.any? && partial_change.nil?
        "【直前の提案】\n提案したスポット: #{previous_context[:spots].join('、')}\n※ユーザーが「変えて」「別の」などと言った場合は、上記と異なるスポットを選んでください\n\n"
      else
        ""
      end

      # 動的なスロット説明を生成
      slot_descriptions = slots.map.with_index(1) do |slot, i|
        hint = SLOT_HINTS[slot] || { name: slot.to_s, hint: "" }
        # 部分変更で維持するスロットにはマーク
        if partial_change&.dig(:keep_indices)&.include?(i - 1)
          "#{i}. #{hint[:name]}: ★維持★"
        else
          "#{i}. #{hint[:name]}: #{hint[:hint]}"
        end
      end.join("\n")

      <<~PROMPT
        あなたはドライブプランのAIアシスタントです。必ずJSON形式で応答してください。

        【#{current_month}月 - #{season_info}】
        【#{start_location_text}】
        #{partial_change_text}
        #{previous_text}【ユーザーの希望】
        #{user_request}

        【候補スポット】
        #{candidates_json}

        【スポット選定ルール】
        候補スポットには以下の情報が含まれています：
        - distance_km: 出発地点からの距離
        - likes: お気に入り数（人気度）※ある場合のみ

        以下の#{slots.size}箇所を選んでください：

        #{slot_descriptions}

        【距離の目安】
        - メインスポット: distance_km が大きい（遠い）場所
        - 帰り道スポット: distance_km が小さい（近い）場所
        - 出発地点から遠い順に並べる

        【重要】
        - likes（お気に入り数）が多いスポットは人気があるので優先的に選ぶ
        - ユーザーの希望（#{user_request}）に最も合うスポットを優先

        【絶対ルール】
        - 候補リストからのみ選ぶ（候補にないものは絶対に提案しない）
        - 宿泊施設（ホテル・旅館・宿）は選ばない
        - 各スポットのgenresを確認し、同じジャンルのスポットを複数選ばない（特にグルメ系は1つまで）
        - 説明文に#{current_month}月の季節感を含める

        【出力JSON】
        {
          "theme": "🍜 絵文字付きテーマ",
          "description": "テーマの説明（1〜2文）",
          "spot_ids": [スポットID, ...],
          "spot_descriptions": {
            "ID": "季節感を含む説明（2〜3文）"
          },
          "closing": "締めの一言"
        }
      PROMPT
    end

    # スポットモード用プロンプト（エリア周辺のおすすめ）
    def build_spots_prompt(candidates, user_request)
      current_month = Time.current.month
      season_info = SEASON_GUIDE[current_month]
      candidates_json = candidates.map { |c|
        base = { id: c[:id], name: c[:name], address: c[:address], genres: c[:genres] }
        base[:likes] = c[:likes_count] if c[:likes_count].to_i > 0
        base
      }.to_json

      <<~PROMPT
        あなたはドライブスポット案内のAIアシスタントです。必ずJSON形式で応答してください。

        【#{current_month}月 - #{season_info}】

        【ユーザーの質問】
        #{user_request}

        【候補スポット】
        #{candidates_json}

        【あなたの役割】
        ユーザーの質問に合う、おすすめスポットを3件選んでください。
        - likes（お気に入り数）が多いスポットは人気があるので優先
        - ユーザーの希望に最も合うスポットを優先
        - #{current_month}月の季節感を含めた説明を付ける

        【絶対ルール】
        - 候補リストからのみ選ぶ（候補にないものは絶対に提案しない）
        - 宿泊施設（ホテル・旅館・宿）は選ばない

        【出力JSON】
        {
          "intro": "導入文（1文）",
          "spot_ids": [スポットID, スポットID, スポットID],
          "spot_descriptions": {
            "ID": "おすすめ理由（1〜2文、季節感を含む）"
          },
          "closing": "締めの一言"
        }
      PROMPT
    end

    # 詳細説明モード用プロンプト
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

    # ============================================
    # レスポンス組み立て
    # ============================================
    def build_final_response(ai_result, candidates, slots = nil, response_mode = :plan)
      slots ||= DEFAULT_SLOTS

      # answerモードの場合は専用レスポンス
      if response_mode == :answer
        return build_answer_response(ai_result, candidates)
      end

      spot_ids = ai_result[:spot_ids] || []
      spot_descriptions = ai_result[:spot_descriptions] || {}

      # 候補からIDで検索してスポット情報を構築
      spots = spot_ids.map do |id|
        candidate = candidates.find { |c| c[:id] == id }
        next nil unless candidate

        {
          spot_id: candidate[:id],
          name: candidate[:name],
          address: candidate[:address],
          description: spot_descriptions[id.to_s.to_sym] || spot_descriptions[id.to_s] || "",
          lat: candidate[:lat],
          lng: candidate[:lng],
          place_id: candidate[:place_id]
        }
      end.compact

      # spotsモードとplanモードで type を切り替え
      response_type = response_mode == :spots ? "spots" : "plan"

      {
        type: response_type,
        message: "",
        intro: response_mode == :spots ? (ai_result[:intro] || "こちらのスポットはいかがですか？") : "",
        spots: spots,
        plan: response_type == "plan" ? {
          theme: ai_result[:theme],
          description: ai_result[:description],
          spots: spots
        } : nil,
        closing: ai_result[:closing] || "",
        slots: slots
      }.compact
    end

    # answerモード用のレスポンス構築
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
