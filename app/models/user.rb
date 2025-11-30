class User < ApplicationRecord
  # Deviseのモジュール
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # 正しいenumの書き方（Rails 8.1以降）
  enum :status, { active: 0, hidden: 1 }

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
