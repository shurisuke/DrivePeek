class Plans::MyPlansController < ApplicationController
  def index
    set_filter_variables

    @plans = current_user.plans
      .search_keyword(@search_query)
      .filter_by_cities(@selected_cities)
      .filter_by_genres(@selected_genre_ids)
      .includes(:start_point, plan_spots: { spot: :genres })
      .order(updated_at: :desc)
      .page(params[:page])
      .per(10)
  end

  private

  def set_filter_variables
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
