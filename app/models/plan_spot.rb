class PlanSpot < ApplicationRecord
  belongs_to :plan
  belongs_to :spot
end
