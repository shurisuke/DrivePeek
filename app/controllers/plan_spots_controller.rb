# app/controllers/plan_spots_controller.rb
class PlanSpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan, only: %i[create destroy]
  before_action :set_plan_spot, only: %i[update destroy]

  # POST /plans/:plan_id/plan_spots
  def create
    @spot = Spot.find(params[:spot_id])
    @plan_spot = @plan.plan_spots.create!(spot: @spot)

    Plan::Recalculator.new(@plan).recalculate!(driving: true, timetable: true)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_myroute_tab" }
    end
  end

  # PATCH /plans/:plan_id/plan_spots/:id
  def update
    @plan_spot.update!(plan_spot_params)

    if params.key?(:toll_used)
      Plan::Recalculator.new(@plan).recalculate!(driving: true, timetable: true)
    elsif params.key?(:stay_duration)
      Plan::Recalculator.new(@plan).recalculate!(driving: false, timetable: true)
    end

    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_myroute_tab" }
    end
  end

  # DELETE /plans/:plan_id/plan_spots/:id
  def destroy
    @spot = @plan_spot.spot
    @plan_spot.destroy!
    Plan::Recalculator.new(@plan).recalculate!(driving: true, timetable: true)
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_myroute_tab" }
      format.html { redirect_to edit_plan_path(@plan), notice: "スポットを削除しました" }
    end
  end

  private

  def set_plan
    @plan = current_user.plans
      .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
      .find(params[:plan_id])
  end

  def set_plan_spot
    @plan_spot = PlanSpot.find(params[:id])
    @plan = current_user.plans
      .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
      .find(@plan_spot.plan_id)
  end

  def plan_spot_params
    params.permit(:toll_used, :memo, :stay_duration)
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
