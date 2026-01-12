class FavoritesController < ApplicationController
  before_action :authenticate_user!

  def index
    set_filter_variables

    if @search_type == "spot"
      @spots = current_user.liked_spots
        .search_keyword(@search_query)
        .filter_by_cities(@selected_cities)
        .filter_by_genres(@selected_genre_ids)
        .includes(:genres)
        .order(created_at: :desc)
        .page(params[:page]).per(10)
    else
      @plans = current_user.liked_plans
        .search_keyword(@search_query)
        .filter_by_cities(@selected_cities)
        .filter_by_genres(@selected_genre_ids)
        .includes(:user, :start_point, :goal_point, plan_spots: { spot: :genres })
        .order(created_at: :desc)
        .page(params[:page]).per(10)
    end
  end

  private

  def set_filter_variables
    @search_type = params[:search_type] == "spot" ? "spot" : "plan"
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
