module PlansHelper
  # 日本の都道府県リスト（地方別）
  PREFECTURES_BY_REGION = {
    "北海道" => %w[北海道],
    "東北" => %w[青森県 岩手県 宮城県 秋田県 山形県 福島県],
    "関東" => %w[茨城県 栃木県 群馬県 埼玉県 千葉県 東京都 神奈川県],
    "中部" => %w[新潟県 富山県 石川県 福井県 山梨県 長野県 岐阜県 静岡県 愛知県],
    "近畿" => %w[三重県 滋賀県 京都府 大阪府 兵庫県 奈良県 和歌山県],
    "中国" => %w[鳥取県 島根県 岡山県 広島県 山口県],
    "四国" => %w[徳島県 香川県 愛媛県 高知県],
    "九州・沖縄" => %w[福岡県 佐賀県 長崎県 熊本県 大分県 宮崎県 鹿児島県 沖縄県]
  }.freeze

  # 全都道府県のフラットリスト
  PREFECTURES = PREFECTURES_BY_REGION.values.flatten.freeze

  # 移動時間をフォーマットして表示（分 → "X時間Y分" or "Y分"）
  # 単位は <span class="plan-summary__unit"> でラップ
  def format_move_time(minutes)
    minutes = minutes.to_i
    hours = minutes / 60
    remaining_minutes = minutes % 60

    parts = []
    if hours.positive?
      parts << hours.to_s
      parts << content_tag(:span, "時間", class: "plan-summary__unit")
    end
    parts << remaining_minutes.to_s
    parts << content_tag(:span, "分", class: "plan-summary__unit")

    safe_join(parts)
  end

  # 距離をフォーマットして表示
  # - 10km以上（整数部2桁以上）: 整数部のみ表示
  # - 10km未満: 小数点以下1桁まで表示
  def format_distance(distance)
    return nil if distance.blank?

    value = distance.to_f
    if value >= 10
      value.to_i.to_s
    else
      number_with_precision(value, precision: 1, strip_insignificant_zeros: true)
    end
  end

  # OGP用の画像URLを返す
  # 将来的にはプラン詳細のスクリーンショット的な画像を動的生成予定
  def ogp_image_url
    # 絶対URLを生成（OGPには絶対URLが必要）
    URI.join(request.base_url, image_path("sample.png")).to_s
  end

  # SNS共有用のテキストを生成（丸数字 + スポット名）
  def share_text_for_plan(plan)
    return "" unless plan&.plan_spots&.any?

    circle_numbers = %w[⓪ ① ② ③ ④ ⑤ ⑥ ⑦ ⑧ ⑨ ⑩ ⑪ ⑫ ⑬ ⑭ ⑮ ⑯ ⑰ ⑱ ⑲ ⑳]
    spot_lines = plan.plan_spots.includes(:spot).order(:position).map.with_index(1) do |ps, i|
      "#{circle_numbers[i] || i.to_s} #{ps.spot.name}"
    end
    "#{spot_lines.join("\n")}\n\n"
  end
end
