class GoalPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  def self.build_from_start_point(plan:, start_point:)
    plan.build_goal_point(
      start_point.attributes.slice("lat", "lng", "address")
    )
  end
end
