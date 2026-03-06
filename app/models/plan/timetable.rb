# app/models/plan/timetable.rb
# frozen_string_literal: true

# 責務: move_time / stay_duration を読み、時刻（arrival_time / departure_time）を計算・保存
#
# 計算フロー:
#   start_point.departure_time + start_point.move_time → spot[1].arrival_time
#   spot[1].arrival_time + spot[1].stay_duration       → spot[1].departure_time
#   spot[1].departure_time + spot[1].move_time         → spot[2].arrival_time
#   ...（繰り返し）
#   spot[n].departure_time + spot[n].move_time         → goal_point.arrival_time
#
# 注意:
#   - API呼び出しなし — 保存済みの move_time を使う
#   - 時刻計算は「分（整数）」で行い、保存時のみ Time に戻す
#
class Plan::Timetable
  DUMMY_DATE = Date.new(2000, 1, 1)

  attr_reader :plan

  def initialize(plan)
    @plan = plan
  end

  # 時刻を再計算して保存
  # @return [Boolean] 成功したか（計算スキップも成功扱い）
  def recalculate!
    ActiveRecord::Base.transaction do
      current_minutes = time_to_minutes(plan.start_point.departure_time)
      plan_spots = plan.plan_spots.order(:position).to_a
      previous_record = plan.start_point

      # 各スポットの到着時刻・出発時刻を計算
      # previous_record.move_time = 前の地点からこのスポットへの移動時間
      plan_spots.each do |plan_spot|
        current_minutes += previous_record.move_time.to_i
        plan_spot.arrival_time = minutes_to_time(current_minutes)

        current_minutes += plan_spot.stay_duration.to_i
        plan_spot.departure_time = minutes_to_time(current_minutes)

        plan_spot.save!
        previous_record = plan_spot
      end

      # goal_point の到着時刻（最後のスポットの move_time を加算）
      if plan.goal_point.present? && plan_spots.any?
        current_minutes += plan_spots.last.move_time.to_i
        plan.goal_point.arrival_time = minutes_to_time(current_minutes)
        plan.goal_point.save!
      end
    end

    true
  end

  private

  # Time → 分（整数）に変換
  # @param time [Time, nil]
  # @return [Integer]
  def time_to_minutes(time)
    return 0 if time.blank?
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
