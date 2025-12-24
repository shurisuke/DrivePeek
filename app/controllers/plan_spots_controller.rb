# app/controllers/plan_spots_controller.rb
class PlanSpotsController < ApplicationController
  include Recalculable

  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_plan_spot, only: %i[destroy]

  def create
    result = SpotSetupService.new(
      plan: @plan,
      user: current_user,
      spot_params: spot_params
    ).setup

    if result.success?
      # ✅ スポット追加後に route → schedule を再計算
      recalculate_route_and_schedule!(@plan)

      render json: {
        plan_spot_id: result.plan_spot.id,
        spot_id: result.spot.id,
        position: result.plan_spot.position
      }, status: :created
    else
      render json: { message: result.error_message, details: result.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    target_id = helpers.dom_id(@plan_spot) # 先に退避しておくと安心
    @plan_spot.destroy!

    # ✅ スポット削除後に route → schedule を再計算
    recalculate_route_and_schedule!(@plan)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(target_id)
      end

      format.html do
        redirect_to edit_plan_path(@plan), notice: "スポットを削除しました"
      end
    end
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def set_plan_spot
    @plan_spot = @plan.plan_spots.find(params[:id])
  end

  def spot_params
    params.require(:spot).permit(
      :place_id, :name, :address, :lat, :lng,
      :photo_reference, top_types: []
    )
  end
end