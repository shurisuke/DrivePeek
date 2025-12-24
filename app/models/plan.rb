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

  # ✅ 合計走行距離（km）
  def total_distance
    distance = start_point&.move_distance.to_f
    distance += plan_spots.sum(:move_distance)
    distance.round(1)
  end

  # ✅ 合計移動時間（分）
  def total_move_time
    time = start_point&.move_time.to_i
    time += plan_spots.sum(:move_time)
    time
  end

  # ✅ 合計移動時間（フォーマット済み文字列）
  def formatted_move_time
    minutes = total_move_time
    return "0分" if minutes.zero?

    hours = minutes / 60
    remaining_minutes = minutes % 60

    if hours.positive?
      "#{hours}時間#{remaining_minutes}分"
    else
      "#{remaining_minutes}分"
    end
  end

  # ✅ 合計有料道路料金
  def total_toll_cost
    cost = 0
    cost += start_point.move_cost.to_i if start_point&.toll_used?
    cost += plan_spots.where(toll_used: true).sum(:move_cost)
    cost
  end

  # ✅ 有料道路使用の有無
  def has_toll_roads?
    return true if start_point&.toll_used?
    plan_spots.exists?(toll_used: true)
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
