# app/models/plan/recalculator.rb
# frozen_string_literal: true

# 責務: 経路/時刻の再計算を実行するオーケストレータ
#
# 実行順序（絶対条件）:
#   1. 経路再計算（Plan::Driving）— move_time 等を確定
#   2. 時刻再計算（Plan::Timetable）— 確定した move_time を読んで時刻を計算
#
# 使い方:
#   - 位置が変わる操作（追加/削除/並び替え） → recalculate!(driving: true, timetable: true)
#   - スケジュールが変わる操作（出発時刻/滞在時間） → recalculate!(driving: false, timetable: true)
#
class Plan::Recalculator
  attr_reader :plan

  def initialize(plan)
    @plan = plan
  end

  # @param driving [Boolean] 経路再計算するか（default: false）
  # @param timetable [Boolean] 時刻再計算するか（default: true）
  # @return [Boolean] 成功したか
  def recalculate!(driving: false, timetable: true)
    success = true

    ActiveRecord::Base.transaction do
      # 必ず driving → timetable の順（driving で move_time が決まってから timetable）
      if driving
        unless Plan::Driving.new(plan).recalculate!
          success = false
          raise ActiveRecord::Rollback
        end
      end

      if timetable
        unless Plan::Timetable.new(plan).recalculate!
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end

    success
  end
end
