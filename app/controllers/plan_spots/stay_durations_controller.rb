# app/controllers/plan_spots/stay_durations_controller.rb
class PlanSpots::StayDurationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan_spot

  # PATCH /plans/:plan_id/plan_spots/:id/update_stay_duration
  def update
    stay_duration = params[:stay_duration].presence&.to_i

    if @plan_spot.update(stay_duration: stay_duration)
      # 時刻再計算（滞在時間変更 → schedule のみ）
      Plan::Recalculator.new(@plan_spot.plan).recalculate!(schedule: true)

      render json: { plan_spot_id: @plan_spot.id, stay_duration: @plan_spot.stay_duration }
    else
      render json: { message: @plan_spot.errors.full_messages.first || "滞在時間の更新に失敗しました" },
             status: :unprocessable_entity
    end
  end

  private

  def set_plan_spot
    @plan_spot =
      PlanSpot
        .joins(:plan)
        .where(plans: { user_id: current_user.id })
        .where(plan_spots: { plan_id: params[:plan_id] })
        .find(params[:id])
  end
end