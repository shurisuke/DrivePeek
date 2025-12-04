class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Enum（アカウントの公開状態）
  enum :status, { public: 0, private: 1, deactivated: 2 }

  # Associations
  has_many :plans, dependent: :destroy
  has_many :user_spots, dependent: :destroy
  has_many :spots, through: :user_spots
  has_many :like_spots, dependent: :destroy
  has_many :liked_spots, through: :like_spots, source: :spot
  has_many :like_plans, dependent: :destroy
  has_many :liked_plans, through: :like_plans, source: :plan

  # Validations
  validates :name, presence: true, length: { maximum: 50 }

  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
end
