# app/controllers/api/plan_spots_controller.rb
module Api
  class PlanSpotsController < BaseController
    before_action :set_plan

    def create
      spot = Spot.find(params[:spot_id])
      plan_spot = @plan.plan_spots.create!(spot: spot)

      @plan.recalculate_for!(plan_spot, action: :create)
      @plan.reload

      respond_to do |format|
        format.turbo_stream { render "plans/refresh_plan_tab" }
        format.json do
          render json: {
            plan_spot_id: plan_spot.id,
            spot_id: spot.id,
            position: plan_spot.position
          }, status: :created
        end
      end
    rescue ActiveRecord::RecordNotFound
      render json: { message: "スポットが見つかりません" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: e.message }, status: :unprocessable_entity
    end

    private

    def set_plan
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(params[:plan_id])
    end
  end
end
