class PlanbarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  def show
    # みんなのプラン: 編集中のプランを除外
    @community_plans = Plan.for_community(
      keyword: params[:q],
      cities: params[:cities],
      genre_ids: params[:genre_ids]
    ).where.not(id: @plan.id)
      .page(params[:page])
      .per(5)

    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end
end