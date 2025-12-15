class Spot < ApplicationRecord
  # Associations
  has_many :user_spots, dependent: :destroy
  has_many :users, through: :user_spots
  has_many :like_spots, dependent: :destroy
  has_many :liked_by_users, through: :like_spots, source: :user
  has_many :plan_spots, dependent: :destroy
  has_many :plans, through: :plan_spots

  # Validations
  validates :place_id, presence: true, uniqueness: true
  validates :name, presence: true
  validates :lat, presence: true
  validates :lng, presence: true

  # Google Places のペイロードを適用
  # - 新規: 全属性をセット
  # - 既存: 空欄のみ補完、photo_reference は常に更新（鮮度優先）
  def apply_google_payload(payload)
    payload = payload.to_h.with_indifferent_access

    self.name    ||= payload[:name]
    self.address ||= payload[:address]
    self.lat     ||= payload[:lat]
    self.lng     ||= payload[:lng]

    # photo_reference は鮮度優先で上書き
    self.photo_reference = payload[:photo_reference] if payload[:photo_reference].present?

    # prefecture / city は ReverseGeocoder で補完
    geocode_if_needed
  end

  private

  def geocode_if_needed
    return if prefecture.present? && city.present?
    return unless lat.present? && lng.present?

    result = ReverseGeocoder.lookup_address(lat: lat, lng: lng)
    self.prefecture ||= result[:prefecture]
    self.city       ||= result[:city]
  end
end
