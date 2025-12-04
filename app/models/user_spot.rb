class UserSpot < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :spot
  has_many :user_spot_tags, dependent: :destroy
  has_many :tags, through: :user_spot_tags

  # Validations
  validates :user_id, uniqueness: { scope: :spot_id }
end
