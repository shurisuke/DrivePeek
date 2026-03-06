class GoalPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  def self.build_from_start_point(plan:, start_point:)
    plan.build_goal_point(
      start_point.attributes.slice("lat", "lng", "address")
    )
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
