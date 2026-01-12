class LikePlan < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :plan

  # Validations
  validates :user_id, uniqueness: { scope: :plan_id }

  # プランIDをキーにしたハッシュを返す（一括取得用）
  def self.index_by_plan_id(user:, plan_ids:)
    return {} unless user
    where(user: user, plan_id: plan_ids).index_by(&:plan_id)
  end
end
