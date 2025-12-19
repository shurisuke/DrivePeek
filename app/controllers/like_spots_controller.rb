class LikeSpotsController < ApplicationController
  before_action :authenticate_user!

  def create
    @spot = Spot.find(params[:spot_id])
    @like_spot = current_user.like_spots.find_or_create_by(spot: @spot)
  end

  def destroy
    @like_spot = current_user.like_spots.find_by(id: params[:id])
    return head :not_found unless @like_spot

    @spot = @like_spot.spot
    @like_spot.destroy
  end
end
