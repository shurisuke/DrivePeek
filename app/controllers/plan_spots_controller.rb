class PlanSpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def create
    result = SpotSetupService.new(
      plan: @plan,
      user: current_user,
      spot_params: spot_params
    ).setup

    if result.success?
      render json: {
        plan_spot_id: result.plan_spot.id,
        spot_id: result.spot.id,
        position: result.plan_spot.position
      }, status: :created
    else
      render json: {
        message: result.error_message,
        details: result.errors
      }, status: :unprocessable_entity
    end
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def spot_params
    params.require(:spot).permit(
      :place_id, :name, :address, :lat, :lng,
      :photo_reference, top_types: []
    )
  end

  def render_not_found
    render json: { message: "プランが見つかりません" }, status: :not_found
  end
end
