class PlanSpot < ApplicationRecord
  # Associations
  belongs_to :plan, counter_cache: true
  belongs_to :spot

  # 順序管理（plan スコープで position を自動採番）
  acts_as_list scope: :plan

  # 滞在時間のデフォルト（60分）と上限（20時間 = 1200分）※ホテル滞在を考慮
  DEFAULT_STAY_DURATION = 60
  MAX_STAY_DURATION = 1200

  attribute :stay_duration, :integer, default: DEFAULT_STAY_DURATION

  # Validations
  validates :spot_id, uniqueness: { scope: :plan_id, message: "は既にこのプランに追加されています" }
  validates :move_time, :move_distance, numericality: { greater_than_or_equal_to: 0 }
  validates :stay_duration, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: MAX_STAY_DURATION,
    allow_nil: true
  }

  # plan配下のplan_spotsだけを対象に、指定順で position を振り直す
  def self.reorder_for_plan!(plan:, ordered_ids:)
    ActiveRecord::Base.transaction do
      ordered_ids.each_with_index do |plan_spot_id, index|
        plan_spot = plan.plan_spots.find(plan_spot_id)
        plan_spot.update!(position: index + 1)
      end
    end
  end
end
