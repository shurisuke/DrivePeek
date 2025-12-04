class LikePlan < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :plan

  # Validations
  validates :user_id, uniqueness: { scope: :plan_id }
end
