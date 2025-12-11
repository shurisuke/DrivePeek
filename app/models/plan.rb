class Plan < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :plan_spots, dependent: :destroy
  has_many :spots, through: :plan_spots
  has_one :start_point, dependent: :destroy
  has_one :goal_point, dependent: :destroy
  has_many :like_plans, dependent: :destroy
  has_many :liked_by_users, through: :like_plans, source: :user

  # before
  before_update :set_default_title_if_blank

  def to_marker_data
    {
      start_point: start_point&.lat && start_point&.lng ? {
        lat: start_point.lat,
        lng: start_point.lng
      } : nil,

      end_point: goal_point&.lat && goal_point&.lng ? {
        lat: goal_point.lat,
        lng: goal_point.lng
      } : nil,

      spots: spots.map do |spot|
        {
          lat: spot.lat,
          lng: spot.lng
        }
      end
    }
  end

  private

  def set_default_title_if_blank
    if title.blank?
      cities = spots.map(&:city).uniq.compact
     self.title = if cities.any?
                     "#{cities.join('・')}の旅"
                   else
                     "ドライブプラン"
                   end
    end
  end
end
