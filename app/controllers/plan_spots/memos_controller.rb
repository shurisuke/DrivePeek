# app/controllers/plan_spots/memos_controller.rb
class PlanSpots::MemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_plan_spot

  def update
    @plan_spot.update!(plan_spot_params)

    memo = @plan_spot.memo.to_s

    render json: {
      plan_spot_id: @plan_spot.id,
      memo: memo,
      memo_html: view_context.simple_format(ERB::Util.h(memo)),
      memo_present: memo.present?
    }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { message: "更新に失敗しました", details: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def set_plan_spot
    @plan_spot = @plan.plan_spots.find(params[:id])
  end

  def plan_spot_params
    params.require(:plan_spot).permit(:memo)
  end
end