class PlanSpot < ApplicationRecord
  # Associations
  belongs_to :plan
  belongs_to :spot

  # 順序管理（plan スコープで position を自動採番）
  acts_as_list scope: :plan

  # 滞在時間の上限（20時間 = 1200分）※ホテル滞在を考慮
  MAX_STAY_DURATION = 1200

  # Validations
  validates :spot_id, uniqueness: { scope: :plan_id, message: "は既にこのプランに追加されています" }
  validates :move_time, :move_distance, numericality: { greater_than_or_equal_to: 0 }
  validates :stay_duration, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: MAX_STAY_DURATION,
    allow_nil: true
  }

  # 経路計算に影響する属性
  ROUTE_AFFECTING_ATTRIBUTES = %w[toll_used].freeze

  # plan配下のplan_spotsだけを対象に、指定順で position を振り直す
  def self.reorder_for_plan!(plan:, ordered_ids:)
    ActiveRecord::Base.transaction do
      ordered_ids.each_with_index do |plan_spot_id, index|
        plan_spot = plan.plan_spots.find(plan_spot_id)
        plan_spot.update!(position: index + 1)
      end
    end
  end

  # 経路に影響する変更があったか
  def route_affecting_changes?
    (saved_changes.keys & ROUTE_AFFECTING_ATTRIBUTES).any?
  end

  # スケジュールに影響する変更があったか
  def schedule_affecting_changes?
    saved_change_to_stay_duration?
  end
end
