# app/models/plan/recalculator.rb
# frozen_string_literal: true

# 責務: Driving と Timetable を適切な順序で呼び出す薄いオーケストレータ
#
# 実行順序（絶対条件）:
#   1. 経路再計算（Plan::Driving）— move_time 等を確定
#   2. 時刻再計算（Plan::Timetable）— 確定した move_time を読んで時刻を計算
#
# 呼び出し元: Controller（必要なタイミングで明示的に呼ぶ）
#
# 使用例:
#   - 出発時間変更     → recalculate!(timetable: true)
#   - 滞在時間変更     → recalculate!(timetable: true)
#   - スポット追加/削除 → recalculate!(driving: true, timetable: true)
#   - 有料道路切替     → recalculate!(driving: true, timetable: true)
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
