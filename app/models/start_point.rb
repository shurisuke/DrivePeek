# app/models/start_point.rb
class StartPoint < ApplicationRecord
  belongs_to :plan

  validates :lat, :lng, :address, presence: true

  # Callbacks
  before_save :geocode_if_needed

  # デフォルト出発時間（09:00）
  DEFAULT_DEPARTURE_TIME = Time.zone.local(2000, 1, 1, 9, 0)

  # Geocoder失敗時のフォールバック（東京駅）
  FALLBACK_LOCATION = {
    lat: 35.681236,
    lng: 139.767125,
    address: "東京都千代田区丸の内一丁目",
    prefecture: "東京都",
    city: "千代田区",
    town: "丸の内"
  }.freeze

  def self.build_from_location(plan:, lat:, lng:)
    attrs = GoogleApi::Geocoder.reverse(lat: lat, lng: lng) || FALLBACK_LOCATION.dup
    attrs[:departure_time] = DEFAULT_DEPARTURE_TIME
    plan.build_start_point(attrs)
  end

  # 短縮住所（県+市+町）
  def short_address
    [ prefecture, city, town ].compact_blank.join
  end

  private

  # prefecture/city/town が未設定なら GoogleApi::Geocoder で補完
  def geocode_if_needed
    return unless lat.present? && lng.present?
    return if prefecture.present? && city.present? && town.present?

    result = GoogleApi::Geocoder.reverse(lat: lat, lng: lng)
    return unless result

    self.prefecture = result[:prefecture] if result[:prefecture].present?
    self.city = result[:city] if result[:city].present?
    self.town = result[:town] if result[:town].present?
  end
end
