class Tag < ApplicationRecord
  # Associations
  has_many :user_spot_tags, dependent: :destroy
  has_many :user_spots, through: :user_spot_tags

  # Validations
  validates :tag_name, presence: true, uniqueness: true
end
