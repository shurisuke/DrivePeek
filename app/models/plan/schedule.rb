# app/models/plan/schedule.rb
# frozen_string_literal: true

# 責務: DBの move_time / stay_duration を読み、時刻カラムを計算・保存する
#
# 入力:
#   - start_points.departure_time
#   - plan_spots.move_time（※「このスポットへ到達する移動時間」の分）
#   - plan_spots.stay_duration（分）
#
# 出力:
#   - plan_spots.arrival_time / departure_time
#   - goal_points.arrival_time
#
# 制約:
#   - 外部API禁止（move_time を取りに行かない）
#   - 時刻計算は「分（整数）」で行い、保存時のみ Time に戻す
#
class Plan::Schedule
  DUMMY_DATE = Date.new(2000, 1, 1)

  attr_reader :plan

  def initialize(plan)
    @plan = plan
  end

  # 時刻を再計算して保存
  # @return [Boolean] 成功したか
  def recalculate!
    return false unless valid_for_calculation?

    ActiveRecord::Base.transaction do
      current_minutes = time_to_minutes(plan.start_point.departure_time)

      plan.plan_spots.order(:position).each do |plan_spot|
        # ✅ 前提: move_time は「このスポットへ到達する」移動時間（分）
        current_minutes += plan_spot.move_time.to_i
        plan_spot.arrival_time = minutes_to_time(current_minutes)

        current_minutes += plan_spot.stay_duration.to_i
        plan_spot.departure_time = minutes_to_time(current_minutes)

        plan_spot.save!
      end

      # goal_point の到着時刻（※ 最終スポット→goal の move_time を別で持つ設計ならここに加算が必要）
      if plan.goal_point.present?
        plan.goal_point.arrival_time = minutes_to_time(current_minutes)
        plan.goal_point.save!
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  def valid_for_calculation?
    plan.start_point.present? && plan.start_point.departure_time.present?
  end

  # Time → 分（整数）に変換
  # @param time [Time, nil]
  # @return [Integer]
  def time_to_minutes(time)
    return 0 if time.nil?
    (time.seconds_since_midnight / 60).to_i
  end

  # 分（整数）→ Time に変換（time型カラムに安全に入れる用）
  # @param minutes [Integer]
  # @return [Time]
  def minutes_to_time(minutes)
    total = minutes.to_i % (24 * 60)
    hours = total / 60
    mins  = total % 60

    Time.zone.local(DUMMY_DATE.year, DUMMY_DATE.month, DUMMY_DATE.day, hours, mins)
  end
end
