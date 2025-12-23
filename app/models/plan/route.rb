# app/models/plan/route.rb
# frozen_string_literal: true

# 責務: 外部API等で move_time / move_distance / move_cost を計算・保存
#
# 入力:
#   - start_point / plan_spots / goal_point の位置情報（lat, lng）
#   - toll_used フラグ
#
# 出力:
#   - plan_spots.move_time / move_distance / move_cost
#
# 制約:
#   - arrival_time / departure_time には一切触らない
#   - 時刻計算は Plan::Schedule の責務
#
class Plan::Route
  attr_reader :plan

  def initialize(plan)
    @plan = plan
  end

  # 経路を再計算して保存
  # @return [Boolean] 成功したか
  def recalculate!
    # TODO: 将来、Google Directions API 等を使って
    # plan_spots.move_time / move_distance / move_cost を更新
    #
    # 実装時の注意:
    #   - plan_spots[0].move_time = start_point → spot[0] の移動時間
    #   - plan_spots[i].move_time = spot[i-1] → spot[i] の移動時間（i > 0）
    #   - 最終スポット → goal の移動時間は別途検討が必要
    true
  end
end
