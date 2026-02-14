# app/controllers/api/start_points_controller.rb
module Api
  class StartPointsController < BaseController
    before_action :set_plan
    before_action :set_start_point

    def update
      # toll_used のみの更新で start_point が未作成の場合は拒否
      if @start_point.new_record? && only_toll_used_param?
        return render json: { ok: false, message: "出発地点を先に設定してください" }, status: :unprocessable_entity
      end

      if @start_point.update(start_point_params)
        @plan.recalculate_for!(@start_point)
        @plan.reload

        # ✅ toll_used のみの更新は JSON レスポンス（アニメーション維持のため）
        if only_toll_used_param?
          render json: build_toll_used_response_json, status: :ok
          return
        end

        # ✅ その他の更新は Turbo Stream で全体を再描画
        @start_point_detail_open = false

        respond_to do |format|
          format.turbo_stream { render "plans/refresh_plan_tab" }
          format.json do
            render json: {
              ok: true,
              start_point: @start_point.as_json(only: %i[lat lng address prefecture city toll_used departure_time])
            }, status: :ok
          end
        end
      else
        render json: { ok: false, errors: @start_point.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      # plan_id は body または query から取得
      plan_id = params[:plan_id] || params.dig(:start_point, :plan_id)
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(plan_id)
    end

    def set_start_point
      @start_point = @plan.start_point || @plan.build_start_point
    end

    def start_point_params
      params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city, :toll_used, :departure_time)
    end

    def only_toll_used_param?
      start_point_params.keys == [ "toll_used" ]
    end

    # ✅ toll_used 更新時の JSON レスポンス
    def build_toll_used_response_json
      {
        toll_used: @start_point.toll_used,
        start_point: {
          departure_time: @start_point.departure_time&.strftime("%H:%M"),
          move_time: @start_point.move_time.to_i,
          move_distance: @start_point.move_distance&.round(1)
        },
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
