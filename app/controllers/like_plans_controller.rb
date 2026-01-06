class LikePlansController < ApplicationController
  before_action :authenticate_user!

  def create
    @plan = Plan.find(params[:plan_id])
    @like_plan = current_user.like_plans.find_or_create_by(plan: @plan)
  end

  def destroy
    @like_plan = current_user.like_plans.find_by(id: params[:id])
    return head :not_found unless @like_plan

    @plan = @like_plan.plan
    @like_plan.destroy
  end
end
