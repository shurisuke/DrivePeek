module PlansHelper
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

  # =============================================
  # plan_card用: スポット間のみの距離・時間・料金
  # スタート地点→最初のスポット、最後のスポット→ゴール地点を除外
  # =============================================

  # スポット間のみの合計距離（km）
  # 最初のスポットのmove_distanceはスタート地点からの距離なので除外
  def spots_only_distance(plan)
    return 0.0 if plan.plan_spots.size <= 1

    plan_spots = plan.plan_spots.loaded? ? plan.plan_spots.sort_by(&:position) : plan.plan_spots.order(:position)
    # 2番目以降のスポットのmove_distanceを合計（スポット間の距離のみ）
    plan_spots.drop(1).sum(&:move_distance).round(1)
  end

  # スポット間のみの合計移動時間（分）
  def spots_only_move_time(plan)
    return 0 if plan.plan_spots.size <= 1

    plan_spots = plan.plan_spots.loaded? ? plan.plan_spots.sort_by(&:position) : plan.plan_spots.order(:position)
    plan_spots.drop(1).sum(&:move_time)
  end

  # スポット間のみの合計移動時間（フォーマット済み文字列）
  def spots_only_formatted_move_time(plan)
    minutes = spots_only_move_time(plan)
    return "0分" if minutes.zero?

    hours = minutes / 60
    remaining_minutes = minutes % 60

    if hours.positive?
      "#{hours}時間#{remaining_minutes}分"
    else
      "#{remaining_minutes}分"
    end
  end

  # スポット間のみの合計ETC料金
  def spots_only_toll_cost(plan)
    return 0 if plan.plan_spots.size <= 1

    plan_spots = plan.plan_spots.loaded? ? plan.plan_spots.sort_by(&:position) : plan.plan_spots.order(:position)
    plan_spots.drop(1).select(&:toll_used?).sum(&:move_cost)
  end
end
