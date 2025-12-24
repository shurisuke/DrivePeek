# app/controllers/concerns/recalculable.rb
# frozen_string_literal: true

# 責務: Plan::Route / Plan::Schedule の再計算呼び出しを共通化する
#
# 使い方:
#   include Recalculable
#   recalculate_route_and_schedule!(@plan)
#
# 順序保証:
#   route → schedule の順で必ず実行される（Recalculator が保証）
#
module Recalculable
  extend ActiveSupport::Concern

  private

  # 経路と時刻を再計算する
  # @param plan [Plan] 対象プラン
  # @return [Boolean] 成功したか
  def recalculate_route_and_schedule!(plan)
    Plan::Recalculator.new(plan).recalculate!(route: true, schedule: true)
  end
end
