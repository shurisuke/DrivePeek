class UserSpotTag < ApplicationRecord
  # Associations
  belongs_to :user_spot
  belongs_to :tag

  # Validations
  validates :user_spot_id, presence: true
  validates :tag_id, presence: true
end
