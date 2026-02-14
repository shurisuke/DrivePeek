# app/controllers/api/plan_spot_reorders_controller.rb
module Api
  class PlanSpotReordersController < BaseController
    before_action :set_plan

    # PATCH /api/plan_spots/reorder
    def update
      ordered_ids = params[:ordered_plan_spot_ids]

      unless ordered_ids.is_a?(Array) && ordered_ids.all? { |id| id.to_s.match?(/\A\d+\z/) }
        return render json: { message: "不正なリクエストです" }, status: :unprocessable_entity
      end

      PlanSpot.reorder_for_plan!(plan: @plan, ordered_ids: ordered_ids.map(&:to_i))
      @plan.recalculate_for!(nil, action: :reorder)
      @plan.reload

      respond_to do |format|
        format.turbo_stream { render "plans/refresh_plan_tab" }
        format.any { head :no_content }
      end
    end

    private

    def set_plan
      # plan_id は body から取得
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(params[:plan_id])
    end
  end
end
