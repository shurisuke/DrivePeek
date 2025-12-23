# app/models/plan/recalculator.rb
# frozen_string_literal: true

# 責務: Route と Schedule を適切な順序で呼び出す薄いオーケストレータ
#
# 実行順序（絶対条件）:
#   1. 経路再計算（Plan::Route）— move_time 等を確定
#   2. 時刻再計算（Plan::Schedule）— 確定した move_time を読んで時刻を計算
#
# 呼び出し元: Controller（必要なタイミングで明示的に呼ぶ）
#
# 使用例:
#   - 出発時間変更     → recalculate!(schedule: true)
#   - 滞在時間変更     → recalculate!(schedule: true)
#   - スポット追加/削除 → recalculate!(route: true, schedule: true) ※将来
#   - 有料道路切替     → recalculate!(route: true, schedule: true) ※将来
#
class Plan::Recalculator
  attr_reader :plan

  def initialize(plan)
    @plan = plan
  end

  # @param route [Boolean] 経路再計算するか（default: false）
  # @param schedule [Boolean] 時刻再計算するか（default: true）
  # @return [Boolean] 成功したか
  def recalculate!(route: false, schedule: true)
    success = true

    ActiveRecord::Base.transaction do
      # 必ず route → schedule の順（route で move_time が決まってから schedule）
      if route
        unless Plan::Route.new(plan).recalculate!
          success = false
          raise ActiveRecord::Rollback
        end
      end

      if schedule
        unless Plan::Schedule.new(plan).recalculate!
          success = false
          raise ActiveRecord::Rollback
        end
      end
    end

    success
  end
end
