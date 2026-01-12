# app/controllers/api/plan_spots/toll_used_controller.rb
module Api
  module PlanSpots
    class TollUsedController < BaseController
      before_action :set_plan
      before_action :set_plan_spot

      # PATCH /api/plans/:plan_id/plan_spots/:id/toll_used
      def update
        toll_used = ActiveModel::Type::Boolean.new.cast(params[:toll_used])

        if @plan_spot.update(toll_used: toll_used)
          @plan.recalculate_for!(@plan_spot)
          @plan.reload

          respond_to do |format|
            format.turbo_stream { render "plans/refresh_plan_tab" }
            format.json do
              render json: {
                plan_spot_id: @plan_spot.id,
                toll_used: @plan_spot.toll_used
              }, status: :ok
            end
          end
        else
          render json: {
            message: "有料道路の設定更新に失敗しました",
            details: @plan_spot.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def set_plan
        @plan = current_user.plans
          .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
          .find(params[:plan_id])
      end

      def set_plan_spot
        @plan_spot = @plan.plan_spots.find(params[:id])
      end
    end
  end
end
