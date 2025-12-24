# app/controllers/start_points_controller.rb
class StartPointsController < ApplicationController
  include Recalculable

  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_start_point

  def update
    # toll_used のみの更新で start_point が未作成の場合は拒否
    if @start_point.new_record? && only_toll_used_param?
      return render json: { ok: false, message: "出発地点を先に設定してください" }, status: :unprocessable_entity
    end

    if @start_point.update(start_point_params)
      # ✅ 経路に影響する変更があれば route → schedule を再計算
      if route_affecting_params?
        recalculate_route_and_schedule!(@plan)
      elsif start_point_params.key?(:departure_time)
        # 出発時間のみ変更 → schedule のみ再計算
        Plan::Recalculator.new(@plan).recalculate!(schedule: true)
      end

      render_success(@start_point)
    else
      render_failure(@start_point)
    end
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end

  def set_start_point
    @start_point = @plan.start_point || @plan.build_start_point
  end

  def start_point_params
    params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city, :toll_used, :departure_time)
  end

  def only_toll_used_param?
    start_point_params.keys == ["toll_used"]
  end

  # 経路に影響するパラメータが含まれているか
  def route_affecting_params?
    route_keys = %w[lat lng address toll_used]
    (start_point_params.keys & route_keys).any?
  end

  def render_success(start_point)
    render json: {
      ok: true,
      start_point: start_point.as_json(only: %i[lat lng address prefecture city toll_used departure_time])
    }, status: :ok
  end

  def render_failure(start_point)
    render json: { ok: false, errors: start_point.errors.full_messages }, status: :unprocessable_entity
  end
end