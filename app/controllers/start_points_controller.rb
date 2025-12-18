# app/controllers/start_points_controller.rb
class StartPointsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan
  before_action :set_start_point

  def update
    # toll_used のみの更新で start_point が未作成の場合は拒否
    if @start_point.new_record? && only_toll_used_param?
      return render json: { ok: false, message: "出発地点を先に設定してください" }, status: :unprocessable_entity
    end

    if @start_point.update(start_point_params)
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
    params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city, :toll_used)
  end

  def only_toll_used_param?
    start_point_params.keys == ["toll_used"]
  end

  def render_success(start_point)
    render json: {
      ok: true,
      start_point: start_point.as_json(only: %i[lat lng address prefecture city toll_used])
    }, status: :ok
  end

  def render_failure(start_point)
    render json: { ok: false, errors: start_point.errors.full_messages }, status: :unprocessable_entity
  end
end