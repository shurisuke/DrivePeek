class Plans::MyPlansController < ApplicationController
  def index
    @search_query = params[:q]
    @plans = current_user.plans
      .search_keyword(@search_query)
      .includes(:start_point, plan_spots: :spot)
      .order(updated_at: :desc)
      .page(params[:page])
      .per(10)

    # user_spotsをプリロード（タグ表示用）
    @user_spots = current_user.user_spots.includes(:tags).index_by(&:spot_id)
  end
end
