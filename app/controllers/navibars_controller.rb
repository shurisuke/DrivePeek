class NavibarsController < ApplicationController
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

  # プランIDからお気に入り情報を取得するハッシュを生成
  def like_plans_by_plan_id(plans)
    return {} unless current_user

    plan_ids = plans.map(&:id)
    current_user.like_plans.where(plan_id: plan_ids).index_by(&:plan_id)
  end
  helper_method :like_plans_by_plan_id

  # スポットIDからお気に入り情報を取得するハッシュを生成
  def like_spots_by_spot_id(spots)
    return {} unless current_user

    spot_ids = spots.map(&:id)
    current_user.like_spots.where(spot_id: spot_ids).index_by(&:spot_id)
  end
  helper_method :like_spots_by_spot_id
end
