class PlanbarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  def show
    # みんなのプラン: 編集中のプランを除外
    @community_plans = Plan.for_community(keyword: params[:q])
      .where.not(id: @plan.id)
      .page(params[:page])
      .per(5)

    @search_query = params[:q]
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end
end