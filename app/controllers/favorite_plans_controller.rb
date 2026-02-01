class FavoritePlansController < ApplicationController
  before_action :authenticate_user!

  def create
    @plan = Plan.find(params[:plan_id])
    @favorite_plan = current_user.favorite_plans.find_or_create_by(plan: @plan)
  end

  def destroy
    @favorite_plan = current_user.favorite_plans.find_by(id: params[:id])
    return head :not_found unless @favorite_plan

    @plan = @favorite_plan.plan
    @favorite_plan.destroy
  end
end
