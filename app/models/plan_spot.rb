class PlanSpot < ApplicationRecord
  # Associations
  belongs_to :plan
  belongs_to :spot

  # 順序管理（plan スコープで position を自動採番）
  acts_as_list scope: :plan

  # Validations
  validates :spot_id, uniqueness: { scope: :plan_id, message: "は既にこのプランに追加されています" }
  validates :move_time, :move_distance, :move_cost, numericality: { greater_than_or_equal_to: 0 }
end
