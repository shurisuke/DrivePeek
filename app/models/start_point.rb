class StartPoint < ApplicationRecord
  # Associations
  belongs_to :plan

  # Validations
  validates :lat, :lng, :address, presence: true
end
