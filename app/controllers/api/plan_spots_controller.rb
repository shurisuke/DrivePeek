# app/controllers/api/plan_spots_controller.rb
module Api
  class PlanSpotsController < BaseController
    before_action :set_plan

    def create
      result = SpotSetupService.new(
        plan: @plan,
        user: current_user,
        spot_params: spot_params
      ).setup

      if result.success?
        @plan.recalculate_for!(result.plan_spot, action: :create)
        @plan.reload

        respond_to do |format|
          format.turbo_stream { render "plans/refresh_plan_tab" }
          format.json do
            render json: {
              plan_spot_id: result.plan_spot.id,
              spot_id: result.spot.id,
              position: result.plan_spot.position
            }, status: :created
          end
        end
      else
        render json: { message: result.error_message, details: result.errors }, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(params[:plan_id])
    end

    def spot_params
      params.require(:spot).permit(
        :place_id, :name, :address, :lat, :lng,
        :photo_reference, top_types: []
      )
    end
  end
end
