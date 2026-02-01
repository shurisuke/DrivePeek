class FavoriteSpotsController < ApplicationController
  before_action :authenticate_user!

  def create
    @spot = Spot.find(params[:spot_id])
    @favorite_spot = current_user.favorite_spots.find_or_create_by(spot: @spot)
  end

  def destroy
    @favorite_spot = current_user.favorite_spots.find_by(id: params[:id])
    return head :not_found unless @favorite_spot

    @spot = @favorite_spot.spot
    @favorite_spot.destroy
  end
end
