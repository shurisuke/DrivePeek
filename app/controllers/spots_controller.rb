class SpotsController < ApplicationController
  def show
    @spot = Spot.includes(:genres).find(params[:id])
    @favorite_spot = current_user&.favorite_spots&.find_by(spot: @spot)
    @related_spots = @spot.related_spots(limit: 5)
    @related_preload = Spot.preload_card_data(@related_spots, current_user)
  end
end
