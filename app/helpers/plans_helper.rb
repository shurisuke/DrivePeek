module PlansHelper
  # プランタイトルを表示用にフォーマット
  # - タイトルが設定されていればそのまま表示
  # - 未設定の場合、スポットの市区町村から自動生成
  def plan_title(plan)
    return plan.title if plan.title.present?

    cities = plan.spots.map(&:city).compact.uniq
    return "未定のプラン" if cities.empty?

    # 市区町村郡の接尾辞を除外（例：宇都宮市 → 宇都宮）
    short_names = cities.map { |c| c.gsub(/[市区町村郡]$/, "") }

    if short_names.size <= 3
      "#{short_names.join('・')}ドライブ"
    else
      "#{short_names.take(3).join('・')}ほかドライブ"
    end
  end

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

  # Google Maps Directions URLを組み立て
  # スポットが0件の場合はnilを返す
  def google_maps_nav_url(plan)
    spots = plan.plan_spots.includes(:spot).order(:position)
    return nil if spots.empty?

    start = plan.start_point
    last = spots.last.spot
    waypoints = spots[0...-1].map(&:spot)

    params = { api: 1, travelmode: "driving" }
    params[:origin] = "#{start.lat},#{start.lng}" if start&.lat && start&.lng
    params[:destination] = last.name
    params[:destination_place_id] = last.place_id if last.place_id.present?

    if waypoints.any?
      params[:waypoints] = waypoints.map(&:name).join("|")
      ids = waypoints.filter_map(&:place_id)
      params[:waypoint_place_ids] = ids.join("|") if ids.any?
    end

    "https://www.google.com/maps/dir/?#{params.to_query}"
  end

  # 選択されたエリアをフォーマット
  # 全市区町村選択時は県名のみ表示
  def format_selected_cities(cities, cities_by_prefecture = {})
    return "エリア" if cities.blank?

    # 都道府県ごとにグループ化
    grouped = cities.group_by { |c| c.split("/").first }

    parts = grouped.map do |pref, city_list|
      all_cities = cities_by_prefecture[pref] || []
      selected_city_names = city_list.map { |c| c.split("/").last }

      # 全選択なら県名のみ
      if all_cities.any? && selected_city_names.sort == all_cities.sort
        pref
      else
        selected_city_names.join(", ")
      end
    end

    parts.join(", ")
  end

  # 選択されたジャンルをフォーマット
  # 親の全子ジャンル選択時は親名のみ表示
  def format_selected_genres(genre_ids, genres_by_category = {})
    return "ジャンル" if genre_ids.blank?

    selected_ids = genre_ids.map(&:to_i).to_set
    parent_names = []

    # カテゴリ内の親子関係をチェック
    genres_by_category.each_value do |groups|
      groups.each do |group|
        children = group[:children]
        if children.present?
          child_ids = children.map(&:id).to_set
          if child_ids.subset?(selected_ids)
            # 全子選択 → 親名を追加
            parent_names << group[:genre].name
            selected_ids -= child_ids
          end
        end
      end
    end

    # 残りの個別選択ジャンル
    remaining = Genre.where(id: selected_ids.to_a).pluck(:name)

    (parent_names + remaining).join(", ")
  end
end
