# app/controllers/goal_points_controller.rb
class GoalPointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  # PATCH /plans/:plan_id/goal_point
  def update
    @goal_point = @plan.goal_point || @plan.build_goal_point
    @goal_point.update!(goal_point_params)
    @plan.recalculate_for!(@goal_point)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_plan_tab" }
    end
  end

  private

  def set_plan
    plan_id = params[:plan_id] || params.dig(:goal_point, :plan_id)
    @plan = current_user.plans
      .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
      .find(plan_id)
  end

  def goal_point_params
    params.require(:goal_point).permit(:address, :lat, :lng)
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
