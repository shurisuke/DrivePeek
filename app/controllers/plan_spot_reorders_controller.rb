# app/controllers/plan_spot_reorders_controller.rb
class PlanSpotReordersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  # PATCH /plans/:plan_id/plan_spots/reorder
  def update
    ordered_ids = params[:ordered_plan_spot_ids]
    return head :unprocessable_entity unless valid_reorder_ids?(ordered_ids)

    @plan.reorder_spots!(ordered_ids)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_plan_tab" }
    end
  end

  private

  def valid_reorder_ids?(ids)
    ids.is_a?(Array) && ids.all? { |id| id.to_s.match?(/\A\d+\z/) }
  end

  def set_plan
    @plan = current_user.plans
      .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
      .find(params[:plan_id])
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
