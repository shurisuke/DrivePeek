# app/models/spot_genre.rb
class SpotGenre < ApplicationRecord
  belongs_to :spot
  belongs_to :genre

  validates :spot_id, uniqueness: { scope: :genre_id }
end
