class Plans::MyPlansController < ApplicationController
  def index
    @search_query = params[:q]
    @plans = current_user.plans
      .search_keyword(@search_query)
      .includes(:start_point, plan_spots: :spot)
      .order(updated_at: :desc)
      .page(params[:page])
      .per(10)
  end
end
