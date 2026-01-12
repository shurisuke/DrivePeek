class GoalPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  def self.build_from_start_point(plan:, start_point:)
    plan.build_goal_point(
      start_point.attributes.slice("lat", "lng", "address")
    )
  end

  # GoalPoint の変更は常に経路に影響
  def route_affecting_changes?
    saved_changes.keys.any? { |k| %w[lat lng address].include?(k) }
  end

  # スケジュールのみに影響する変更はない
  def schedule_affecting_changes?
    false
  end
end
