# app/controllers/api/plan_spots/toll_used_controller.rb
module Api
  module PlanSpots
    class TollUsedController < BaseController
      include Recalculable

      before_action :set_plan
      before_action :set_plan_spot

      # PATCH /api/plans/:plan_id/plan_spots/:id/toll_used
      def update
        toll_used = ActiveModel::Type::Boolean.new.cast(params[:toll_used])

        if @plan_spot.update(toll_used: toll_used)
          # 有料道路切替後に route → schedule を再計算
          recalculate_route_and_schedule!(@plan)

          render json: {
            plan_spot_id: @plan_spot.id,
            toll_used: @plan_spot.toll_used
          }, status: :ok
        else
          render json: {
            message: "有料道路の設定更新に失敗しました",
            details: @plan_spot.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_plan
        @plan = current_user.plans.find(params[:plan_id])
      end

      def set_plan_spot
        @plan_spot = @plan.plan_spots.find(params[:id])
      end
    end
  end
end
