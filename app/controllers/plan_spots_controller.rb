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

  def reorder
    ordered_ids = params[:ordered_plan_spot_ids]

    unless ordered_ids.is_a?(Array) && ordered_ids.all? { |id| id.is_a?(Integer) || id.to_i.to_s == id.to_s }
      return render json: { message: "不正なリクエストです" }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      ordered_ids.each_with_index do |plan_spot_id, index|
        plan_spot = @plan.plan_spots.find(plan_spot_id)
        plan_spot.update!(position: index + 1)
      end
    end

    head :no_content
  rescue ActiveRecord::RecordNotFound
    render json: { message: "スポットが見つかりません" }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: "並び替えに失敗しました", details: e.message }, status: :unprocessable_entity
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
