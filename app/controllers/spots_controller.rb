class SpotsController < ApplicationController
  def show
    @spot = Spot.includes(:genres).find(params[:id])
    @like_spot = current_user&.like_spots&.find_by(spot: @spot)
  end
end
