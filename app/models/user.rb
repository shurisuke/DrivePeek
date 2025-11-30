class User < ApplicationRecord
  # Deviseのモジュール（必要に応じて調整）
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # ステータス管理
  enum status: { public: 0, private: 1 }

  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
