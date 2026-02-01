# app/controllers/api/plans/plan_spots_controller.rb
module Api
  module Plans
    class PlanSpotsController < BaseController
      before_action :set_plan, only: %i[create]
      before_action :set_plan_spot, only: %i[update]

      # POST /api/plan_spots
      def create
        @spot = Spot.find(params[:spot_id])
        @plan_spot = @plan.plan_spots.create!(spot: @spot)

        @plan.recalculate_for!(@plan_spot, action: :create)
        @plan.reload

        respond_to do |format|
          format.turbo_stream { render "plans/refresh_plan_tab" }
          format.json do
            render json: {
              plan_spot_id: @plan_spot.id,
              spot_id: @spot.id,
              position: @plan_spot.position
            }, status: :created
          end
        end
      rescue ActiveRecord::RecordNotFound
        render json: { message: "スポットが見つかりません" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { message: e.message }, status: :unprocessable_entity
      end

      # PATCH /api/plan_spots/:id
      # toll_used, memo, stay_duration を統合
      def update
        @plan_spot.update!(plan_spot_params)

        # toll_used または stay_duration が更新された場合は再計算
        if needs_recalculation?
          @plan.recalculate_for!(@plan_spot)
          @plan.reload
        end

        respond_to do |format|
          format.turbo_stream { render "plans/refresh_plan_tab" }
          format.json { render json: build_response_json, status: :ok }
        end
      rescue ActiveRecord::RecordInvalid => e
        render json: { message: "更新に失敗しました", details: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      private

      def set_plan
        @plan = current_user.plans
          .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
          .find(params[:plan_id])
      end

      def set_plan_spot
        @plan_spot = PlanSpot.find(params[:id])
        @plan = current_user.plans
          .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
          .find(@plan_spot.plan_id)
      end

      def plan_spot_params
        params.permit(:toll_used, :memo, :stay_duration)
      end

      def needs_recalculation?
        params.key?(:toll_used) || params.key?(:stay_duration)
      end

      def build_response_json
        response = { plan_spot_id: @plan_spot.id }

        # memo が更新された場合
        if params.key?(:memo)
          memo = @plan_spot.memo.to_s
          memo_icon = '<i class="bi bi-sticky spot-memo__icon" aria-hidden="true"></i>'
          memo_text = view_context.simple_format(ERB::Util.h(memo))
          response.merge!(
            memo: memo,
            memo_html: memo.present? ? "#{memo_icon}#{memo_text}" : "",
            memo_present: memo.present?
          )
        end

        # toll_used が更新された場合
        if params.key?(:toll_used)
          response.merge!(
            toll_used: @plan_spot.toll_used,
            spots: build_spots_json,
            footer: build_footer_json
          )
        end

        # stay_duration が更新された場合
        if params.key?(:stay_duration)
          response[:stay_duration] = @plan_spot.stay_duration
          # 再計算後の時間情報も含める
          response[:spots] ||= build_spots_json
          response[:footer] ||= build_footer_json
        end

        response
      end

      def build_spots_json
        @plan.plan_spots.order(:position).map do |ps|
          {
            id: ps.id,
            arrival_time: ps.arrival_time&.strftime("%H:%M"),
            departure_time: ps.departure_time&.strftime("%H:%M"),
            move_time: ps.move_time.to_i,
            move_distance: ps.move_distance&.round(1)
          }
        end
      end

      def build_footer_json
        {
          spots_only_distance: @plan.start_to_last_spot_distance&.round(1),
          spots_only_time: @plan.start_to_last_spot_move_time.to_i,
          with_goal_distance: @plan.total_distance&.round(1),
          with_goal_time: @plan.total_move_time.to_i
        }
      end
    end
  end
end
