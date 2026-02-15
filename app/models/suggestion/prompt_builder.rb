# frozen_string_literal: true

# 提案用プロンプト生成を担当
#
# 使い方:
#   prompt = Suggestion::PromptBuilder.plan_mode(slot_data, 10.0)
#   prompt = Suggestion::PromptBuilder.spot_mode(candidates, genre, 10.0)
#
class Suggestion::PromptBuilder
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
    # プランモード用プロンプトを生成
    # @param slot_data [Array<Hash>] [{ genre_name:, candidates: [...] }, ...]
    # @param radius_km [Float] 半径
    # @return [String] プロンプト
    def plan_mode(slot_data, radius_km)
      month = Time.current.month
      season = SEASON_GUIDE[month]
      area_name = slot_data.first&.dig(:candidates)&.first&.dig(:city) || "選択エリア"

      # スロットごとに候補を通し番号で列挙
      index = 1
      slots_info = slot_data.map do |slot|
        spots_list = slot[:candidates].map do |s|
          "#{index}.#{s[:name]}".tap { index += 1 }
        end.join(" ")
        "[#{slot[:genre_name]}] #{spots_list}"
      end.join("\n")

      <<~PROMPT
        あなたはドライブプランAIです。

        ■ #{month}月・#{season} / #{area_name}周辺（半径#{radius_km.round(1)}km）

        ■ 候補スポット
        #{slots_info}

        ■ タスク
        各ジャンルから季節に合った1件を必ず選出（同じジャンルから複数選ばない）。
        ※自然・公園系は花や紅葉の見頃を考慮（例: コキアは秋、桜は春）

        ■ 文章ルール（すべて敬語）
        - intro: 地域の特徴や魅力（季節に言及しない）
        - d: スポット固有の魅力（スポット名は含めない、季節は本当に関係する場合のみ）

        ■ JSON
        {"picks":[{"n":番号,"d":"1文"},...], "intro":"1文", "closing":"1文"}
      PROMPT
    end

    # スポットモード用プロンプトを生成
    # @param candidates [Array<Hash>] [spot_hash, ...]
    # @param genre [Genre] 対象ジャンル
    # @param radius_km [Float] 半径
    # @return [String] プロンプト
    def spot_mode(candidates, genre, radius_km)
      area_name = candidates.first&.dig(:city) || "選択エリア"
      spots_list = candidates.map { |s| s[:name] }.join("、")
      genre_name = genre&.name || "おまかせ（全ジャンル）"

      <<~PROMPT
        あなたはドライブスポット紹介AIです。

        ■ #{area_name}周辺（半径#{radius_km.round(1)}km）
        ■ ジャンル: #{genre_name}

        ■ 人気スポット
        #{spots_list}

        ■ タスク
        上記の人気スポットをシンプルに紹介。

        ■ JSON
        {"intro":"紹介文（1〜2文）","closing":"気になるスポットの追加を促す一言"}
      PROMPT
    end
  end
end
