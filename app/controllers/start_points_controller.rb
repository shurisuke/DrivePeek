# app/controllers/start_points_controller.rb
class StartPointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_start_point

  # PATCH /plans/:plan_id/start_point
  def update
    update_params = build_update_params
    @start_point.update!(update_params)

    # 経路影響（lat, lng, address, toll_used）→ 経路再計算
    # 時間影響（departure_time）→ スケジュール再計算のみ
    if route_affecting?(update_params)
      Plan::Recalculator.new(@plan).recalculate!(driving: true, timetable: true)
    else
      Plan::Recalculator.new(@plan).recalculate!(driving: false, timetable: true)
    end
    reload_plan

    respond_to do |format|
      format.turbo_stream { render "plans/refresh_myroute_tab" }
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
    params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city, :town, :toll_used, :departure_time, :address_query)
  end

  # address_query がある場合はジオコーディングして全情報を取得
  def build_update_params
    permitted = start_point_params.to_h.symbolize_keys
    query = permitted.delete(:address_query)
    return permitted if query.blank?

    geocoded = GoogleApi::Geocoder.forward(query)
    permitted.merge(geocoded || { address: query })
  end

  def route_affecting?(update_params)
    route_attrs = %i[lat lng address toll_used]
    (update_params.keys & route_attrs).any?
  end

  def reload_plan
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)
  end
end
