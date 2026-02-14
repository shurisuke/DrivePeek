# app/controllers/spot_genres_controller.rb
class SpotGenresController < ApplicationController
  before_action :set_spot

  # GET /spots/:spot_id/genres
  def show
    @spot.detect_genres!
    @spot.reload

    partial = params[:inline] == "true" ? "spots/genres_inline" : "spots/genres"
    render partial: partial, locals: { spot: @spot }
  end

  private

  def set_spot
    @spot = Spot.find(params[:spot_id])
  end
end
