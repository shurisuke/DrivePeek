# app/controllers/api/goal_points_controller.rb
module Api
  class GoalPointsController < BaseController
    before_action :set_plan

    def update
      @goal_point = @plan.goal_point || @plan.build_goal_point
      @goal_point.update!(goal_point_params)
      @plan.recalculate_for!(@goal_point)
      @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

      respond_to do |format|
        format.turbo_stream { render "plans/refresh_plan_tab" }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: "帰宅地点の更新に失敗しました", details: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_plan
      # plan_id は body または query から取得
      plan_id = params[:plan_id] || params.dig(:goal_point, :plan_id)
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(plan_id)
    end

    def goal_point_params
      params.require(:goal_point).permit(:address, :lat, :lng)
    end
  end
end
