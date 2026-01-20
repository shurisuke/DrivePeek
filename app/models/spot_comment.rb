class SpotComment < ApplicationRecord
  belongs_to :user
  belongs_to :spot

  validates :body, presence: true, length: { maximum: 100 }

  # 新しい順
  scope :recent, -> { order(created_at: :desc) }

  # 古い順（チャット方式用）
  scope :chronological, -> { order(created_at: :asc) }
end
