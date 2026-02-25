# app/controllers/goal_points_controller.rb
class GoalPointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  # PATCH /plans/:plan_id/goal_point
  def update
    @goal_point = @plan.goal_point || @plan.build_goal_point
    @goal_point.update!(build_update_params)
    @plan.recalculate_for!(@goal_point)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_myroute_tab" }
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
    params.require(:goal_point).permit(:address, :lat, :lng, :address_query)
  end

  # address_query がある場合はジオコーディングして座標を取得
  def build_update_params
    permitted = goal_point_params.to_h.symbolize_keys
    query = permitted.delete(:address_query)
    return permitted if query.blank?

    geocoded = GoogleApi::Geocoder.forward(query)
    permitted.merge(geocoded&.slice(:lat, :lng, :address) || { address: query })
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
