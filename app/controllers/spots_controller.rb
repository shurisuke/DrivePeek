class SpotsController < ApplicationController
  def show
    @spot = Spot.includes(:genres).find(params[:id])
    @favorite_spot = current_user&.favorite_spots&.find_by(spot: @spot)
  end
end
