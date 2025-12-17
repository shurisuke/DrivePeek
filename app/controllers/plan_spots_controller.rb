# app/controllers/plan_spots_controller.rb
class PlanSpotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

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
      render json: { message: result.error_message, details: result.errors }, status: :unprocessable_entity
    end
  end

  def reorder
    ordered_ids = params[:ordered_plan_spot_ids]

    unless ordered_ids.is_a?(Array) && ordered_ids.all? { |id| id.to_s.match?(/\A\d+\z/) }
      return render json: { message: "不正なリクエストです" }, status: :unprocessable_entity
    end

    PlanSpot.reorder_for_plan!(plan: @plan, ordered_ids: ordered_ids.map(&:to_i))
    head :no_content
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
end