# app/models/plan/timetable.rb
# frozen_string_literal: true

# 責務: DBの move_time / stay_duration を読み、時刻カラムを計算・保存する
#
# 入力:
#   - start_points.departure_time（出発時刻）
#   - start_points.move_time（start → first_spot の移動時間）
#   - plan_spots.move_time（このスポット → 次のスポット/goal への移動時間）
#   - plan_spots.stay_duration（このスポットでの滞在時間）
#
# 出力:
#   - plan_spots.arrival_time / departure_time
#   - goal_points.arrival_time
#
# move_time の保存先ルール（Driving と共通）:
#   - 「次の区間までの情報は出発側に保存する」
#   - start_point.move_time = start → first_spot
#   - plan_spot[n].move_time = spot[n] → spot[n+1] or goal
#
# 制約:
#   - 外部API禁止（move_time を取りに行かない）
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
    # 出発時間が未設定の場合は計算をスキップ（成功扱い）
    # ※ Driving の計算結果をロールバックさせないため
    return true unless valid_for_calculation?

    ActiveRecord::Base.transaction do
      current_minutes = time_to_minutes(plan.start_point.departure_time)
      plan_spots = plan.plan_spots.order(:position).to_a

      plan_spots.each_with_index do |plan_spot, index|
        # ✅ 移動時間の取得先:
        #   - 最初のスポット: start_point.move_time（start → spot1）
        #   - 2番目以降: 前のスポットの move_time（spot[n-1] → spot[n]）
        move_time = if index == 0
                      plan.start_point.move_time.to_i
        else
                      plan_spots[index - 1].move_time.to_i
        end

        current_minutes += move_time
        plan_spot.arrival_time = minutes_to_time(current_minutes)

        current_minutes += plan_spot.stay_duration.to_i
        plan_spot.departure_time = minutes_to_time(current_minutes)

        plan_spot.save!
      end

      # goal_point の到着時刻
      # ✅ 最後のスポットの move_time（last_spot → goal）を加算
      if plan.goal_point.present? && plan_spots.any?
        last_spot_move_time = plan_spots.last.move_time.to_i
        goal_arrival_minutes = current_minutes + last_spot_move_time
        plan.goal_point.arrival_time = minutes_to_time(goal_arrival_minutes)
        plan.goal_point.save!
      end
    end

    true
  end

  private

  def valid_for_calculation?
    plan.start_point.present? && plan.start_point.departure_time.present?
  end

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
