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

          render json: build_response_json, status: :ok
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

      # ✅ 全スポットの時間・距離情報を含む JSON を構築
      def build_response_json
        {
          plan_spot_id: @plan_spot.id,
          toll_used: @plan_spot.toll_used,
          spots: @plan.plan_spots.order(:position).map do |ps|
            {
              id: ps.id,
              arrival_time: ps.arrival_time&.strftime("%H:%M"),
              departure_time: ps.departure_time&.strftime("%H:%M"),
              move_time: ps.move_time.to_i,
              move_distance: ps.move_distance&.round(1)
            }
          end,
          footer: {
            spots_only_distance: @plan.start_to_last_spot_distance&.round(1),
            spots_only_time: @plan.start_to_last_spot_move_time.to_i,
            with_goal_distance: @plan.total_distance&.round(1),
            with_goal_time: @plan.total_move_time.to_i
          }
        }
      end
    end
  end
end
