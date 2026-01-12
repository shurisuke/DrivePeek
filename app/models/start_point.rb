# app/models/start_point.rb
class StartPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  # 経路計算に影響する属性
  ROUTE_AFFECTING_ATTRIBUTES = %w[lat lng address toll_used].freeze

  def self.build_from_location(plan:, lat:, lng:)
    attrs = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
    plan.build_start_point(attrs)
  end

  # 経路に影響する変更があったか
  def route_affecting_changes?
    (saved_changes.keys & ROUTE_AFFECTING_ATTRIBUTES).any?
  end

  # スケジュールに影響する変更があったか
  def schedule_affecting_changes?
    saved_change_to_departure_time?
  end
end
