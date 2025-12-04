class PlanSpot < ApplicationRecord
  # Associations
  belongs_to :plan
  belongs_to :spot

  # Validations
  validates :position, presence: true
  validates :move_time, :move_distance, :move_cost, numericality: { greater_than_or_equal_to: 0 }
end
