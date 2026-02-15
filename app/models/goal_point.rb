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

  # 表示用住所（出発地点と同じならshort_address、違えばaddress）
  def display_address
    start_point = plan.start_point
    return address if start_point.blank?

    if lat == start_point.lat && lng == start_point.lng
      start_point.short_address.presence || address
    else
      address
    end
  end
end
