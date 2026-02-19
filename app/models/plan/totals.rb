# app/models/plan/totals.rb
# frozen_string_literal: true

# 距離・時間の集計メソッドを集約（表示用）
module Plan::Totals
  extend ActiveSupport::Concern

  # 合計走行距離（km）
  # preload済みのplan_spotsがあればRubyで計算、なければSQLで計算
  def total_distance
    distance = start_point&.move_distance.to_f
    distance += if plan_spots.loaded?
                  plan_spots.sum(&:move_distance)
    else
                  plan_spots.sum(:move_distance)
    end
    distance.round(1)
  end

  # 合計移動時間（分）
  # preload済みのplan_spotsがあればRubyで計算、なければSQLで計算
  def total_move_time
    time = start_point&.move_time.to_i
    time += if plan_spots.loaded?
              plan_spots.sum(&:move_time)
    else
              plan_spots.sum(:move_time)
    end
    time
  end

  # スポット間のみの合計距離（公開用：start→spot1 と lastSpot→goal を除く）
  def spots_only_distance
    spots = ordered_plan_spots
    return 0.0 if spots.size < 2

    spots[0..-2].sum(&:move_distance).to_f.round(1)
  end

  # スポット間のみの合計時間（公開用：start→spot1 と lastSpot→goal を除く）
  def spots_only_move_time
    spots = ordered_plan_spots
    return 0 if spots.size < 2

    spots[0..-2].sum(&:move_time).to_i
  end

  # 出発地点→最後のスポットまでの距離（帰宅地点を除く）
  def start_to_last_spot_distance
    spots = ordered_plan_spots
    return 0.0 if spots.empty?

    distance = start_point&.move_distance.to_f
    distance += spots[0..-2].sum(&:move_distance) if spots.size > 1
    distance.round(1)
  end

  # 出発地点→最後のスポットまでの時間（帰宅地点を除く）
  def start_to_last_spot_move_time
    spots = ordered_plan_spots
    return 0 if spots.empty?

    time = start_point&.move_time.to_i
    time += spots[0..-2].sum(&:move_time) if spots.size > 1
    time
  end

  # 合計移動時間（フォーマット済み文字列）
  def formatted_move_time
    minutes = total_move_time
    return "0分" if minutes.zero?

    hours = minutes / 60
    remaining_minutes = minutes % 60

    if hours.positive?
      "#{hours}時間#{remaining_minutes}分"
    else
      "#{remaining_minutes}分"
    end
  end
end
