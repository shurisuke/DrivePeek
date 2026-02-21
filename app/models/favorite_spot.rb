class FavoriteSpot < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :spot, counter_cache: true

  # Validations
  validates :user_id, uniqueness: { scope: :spot_id }

  # スポットIDをキーにしたハッシュを返す（一括取得用）
  def self.index_by_spot_id(user:, spot_ids:)
    return {} unless user
    where(user: user, spot_id: spot_ids).index_by(&:spot_id)
  end
end
