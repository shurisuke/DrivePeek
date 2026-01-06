# app/controllers/plan_spots_controller.rb
# Turbo Stream 用（destroy のみ）
# create は Api::PlanSpotsController へ移動済み
class PlanSpotsController < ApplicationController
  include Recalculable

  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_plan_spot, only: %i[destroy]

  def destroy
    target_id = helpers.dom_id(@plan_spot)
    @plan_spot.destroy!

    # スポット削除後に route → schedule を再計算
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
end
