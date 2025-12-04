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
end
