# app/controllers/plan_spot_adoptions_controller.rb
class PlanSpotAdoptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  # POST /plans/:plan_id/plan_spots/adopt
  def create
    spot_ids = extract_spot_ids(params[:spots])
    return head :unprocessable_entity if spot_ids.empty?

    @plan.adopt_spots!(spot_ids)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_plan_tab" }
    end
  end

  private

  def extract_spot_ids(spots_param)
    Array(spots_param).filter_map { |s| s["spot_id"] || s[:spot_id] }.map(&:to_i)
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
