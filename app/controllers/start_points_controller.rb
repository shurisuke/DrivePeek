# app/controllers/start_points_controller.rb
class StartPointsController < ApplicationController
  before_action :set_plan
  before_action :set_start_point

  def update
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
    # あれば取得/なければ生成
    @start_point = @plan.start_point || @plan.build_start_point
  end

  def start_point_params
    params.require(:start_point).permit(:lat, :lng, :address, :prefecture, :city)
  end

  # 成功レスポンスの形を固定
  def render_success(start_point)
    render json: {
      ok: true,
      start_point: start_point.as_json(only: %i[lat lng address prefecture city])
    }, status: :ok
  end

  # 失敗レスポンスも固定
  def render_failure(start_point)
    render json: { ok: false, errors: start_point.errors.full_messages }, status: :unprocessable_entity
  end
end