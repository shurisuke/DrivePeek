# app/controllers/start_points_controller.rb
class StartPointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_start_point

  # PATCH /plans/:plan_id/start_point
  def update
    @start_point.update!(start_point_params)

    # 経路影響（lat, lng, address, toll_used）→ 経路再計算
    # 時間影響（departure_time）→ スケジュール再計算のみ
    if route_affecting_params?
      @plan.recalculate_for!(@start_point, action: :reorder)
    else
      @plan.recalculate_for!(@start_point, action: :update)
    end
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_plan_tab" }
    end
  end

  private

  def set_plan
    plan_id = params[:plan_id] || params.dig(:start_point, :plan_id)
    @plan = current_user.plans
      .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
      .find(plan_id)
  end

  def set_start_point
    @start_point = @plan.start_point
  end

  def start_point_params
    params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city, :toll_used, :departure_time)
  end

  def route_affecting_params?
    route_attrs = %w[lat lng address toll_used]
    (start_point_params.keys & route_attrs).any?
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
