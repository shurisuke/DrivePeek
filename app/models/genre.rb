# app/models/genre.rb
class Genre < ApplicationRecord
  has_many :spot_genres, dependent: :destroy
  has_many :spots, through: :spot_genres

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :position, presence: true

  scope :ordered, -> { order(:position) }
end
