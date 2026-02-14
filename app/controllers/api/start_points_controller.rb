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
        # 経路影響（lat, lng, address, toll_used）→ 経路再計算
        # 時間影響（departure_time）→ スケジュール再計算のみ
        if route_affecting_params?
          @plan.recalculate_for!(@start_point, action: :reorder)
        else
          @plan.recalculate_for!(@start_point, action: :update)
        end
        @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

        respond_to do |format|
          format.turbo_stream { render "plans/refresh_plan_tab" }
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

    def route_affecting_params?
      route_attrs = %w[lat lng address toll_used]
      (start_point_params.keys & route_attrs).any?
    end
  end
end
