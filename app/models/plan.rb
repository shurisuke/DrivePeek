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

  def marker_data_for_edit
    {
      start_point: lat_lng_hash(start_point),
      end_point:   lat_lng_hash(goal_point),
      spots:       spots.map { |spot| lat_lng_hash(spot) }.compact
    }
  end

  def marker_data_for_public_view
    {
      spots: spots.map { |spot| lat_lng_hash(spot) }.compact
    }
  end

  private

  def lat_lng_hash(record)
    return nil unless record&.lat.present? && record&.lng.present?
    { lat: record.lat, lng: record.lng }
  end

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
