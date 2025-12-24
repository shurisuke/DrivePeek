# app/controllers/goal_points_controller.rb
# ※ start_point と同じ更新方式の goal_point 版
class GoalPointsController < ApplicationController
  include Recalculable

  before_action :authenticate_user!
  before_action :set_plan

  def update
    goal_point = @plan.goal_point || @plan.build_goal_point
    goal_point.update!(goal_point_params)

    # ✅ 帰宅地点変更後に route → schedule を再計算
    recalculate_route_and_schedule!(@plan)

    render json: {
      address: goal_point.address,
      lat: goal_point.lat,
      lng: goal_point.lng
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: "帰宅地点の更新に失敗しました", details: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def goal_point_params
    params.require(:goal_point).permit(:address, :lat, :lng)
  end
end