class PlanSpot < ApplicationRecord
  # Associations
  belongs_to :plan
  belongs_to :spot

  # 順序管理（plan スコープで position を自動採番）
  acts_as_list scope: :plan

  # Validations
  validates :spot_id, uniqueness: { scope: :plan_id, message: "は既にこのプランに追加されています" }
  validates :move_time, :move_distance, :move_cost, numericality: { greater_than_or_equal_to: 0 }

  # plan配下のplan_spotsだけを対象に、指定順で position を振り直す
  def self.reorder_for_plan!(plan:, ordered_ids:)
    ActiveRecord::Base.transaction do
      ordered_ids.each_with_index do |plan_spot_id, index|
        plan_spot = plan.plan_spots.find(plan_spot_id) # 見つからない場合 RecordNotFound
        plan_spot.update!(position: index + 1)         # バリデーションNGで RecordInvalid
      end
    end
  end
end
