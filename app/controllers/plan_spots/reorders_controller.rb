# app/controllers/plan_spots/reorders_controller.rb
module PlanSpots
  class ReordersController < ApplicationController
    include Recalculable

    before_action :authenticate_user!
    before_action :set_plan

    # PATCH /plans/:plan_id/plan_spots/reorder
    def update
      ordered_ids = params[:ordered_plan_spot_ids]

      unless ordered_ids.is_a?(Array) && ordered_ids.all? { |id| id.to_s.match?(/\A\d+\z/) }
        return render json: { message: "不正なリクエストです" }, status: :unprocessable_entity
      end

      PlanSpot.reorder_for_plan!(plan: @plan, ordered_ids: ordered_ids.map(&:to_i))

      # ✅ 並び替え後に route → schedule を再計算
      recalculate_route_and_schedule!(@plan)

      head :no_content
    end

    private

    def set_plan
      @plan = current_user.plans.find(params[:plan_id])
    end
  end
end