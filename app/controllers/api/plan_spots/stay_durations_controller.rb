# app/controllers/api/plan_spots/stay_durations_controller.rb
module Api
  module PlanSpots
    class StayDurationsController < BaseController
      before_action :set_plan
      before_action :set_plan_spot

      # PATCH /api/plans/:plan_id/plan_spots/:id/stay_duration
      def update
        stay_duration = params[:stay_duration].presence&.to_i

        if @plan_spot.update(stay_duration: stay_duration)
          @plan.recalculate_for!(@plan_spot)
          @plan.reload

          respond_to do |format|
            format.turbo_stream { render "plans/refresh_plan_tab" }
            format.json { render json: { plan_spot_id: @plan_spot.id, stay_duration: @plan_spot.stay_duration } }
          end
        else
          render json: { message: @plan_spot.errors.full_messages.first || "滞在時間の更新に失敗しました" },
                 status: :unprocessable_entity
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
