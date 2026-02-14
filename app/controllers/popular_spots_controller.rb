# app/controllers/popular_spots_controller.rb
class PopularSpotsController < ApplicationController
  # GET /popular_spots
  def index
    spots = Spot.popular_in_bounds(
      north: params[:north].to_f,
      south: params[:south].to_f,
      east: params[:east].to_f,
      west: params[:west].to_f,
      genre_ids: params[:genre_ids],
      limit: (params[:limit] || 10).to_i
    )

    render json: { spots: spots.map { |s| spot_json(s) } }
  end

  private

  def spot_json(spot)
    genre = spot.genres.first
    {
      id: spot.id,
      name: spot.name,
      lat: spot.lat,
      lng: spot.lng,
      favorites_count: spot.favorites_count,
      emoji: genre&.emoji || "✨"
    }
  end
end
