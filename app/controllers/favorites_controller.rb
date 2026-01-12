class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def index
    @tab = params[:tab] == "spot" ? "spot" : "plan"

    if @tab == "spot"
      @spots = current_user.liked_spots
        .includes(:genres)
        .order(created_at: :desc)
        .page(params[:page]).per(10)
    else
      @plans = current_user.liked_plans
        .includes(:user, :start_point, :goal_point, plan_spots: { spot: :genres })
        .order(created_at: :desc)
        .page(params[:page]).per(10)
    end
  end
end
