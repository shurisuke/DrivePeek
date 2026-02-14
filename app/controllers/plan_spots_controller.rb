# app/controllers/plan_spots_controller.rb
# Turbo Stream 用（destroy のみ）
# create は Api::PlanSpotsController へ移動済み
class PlanSpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_plan_spot, only: %i[destroy]

  def destroy
    @spot = @plan_spot.spot
    @plan_spot.destroy!
    @plan.recalculate_for!(@plan_spot, action: :destroy)
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_plan_tab" }
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
    @plan_spot = @plan.plan_spots.find(params[:id])
  end
end
