class PlanbarsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_plan

  def show
    # 何もしない：format に応じて view を自動で探して描画する
    # show.turbo_stream.erb / show.html.erb に責務を寄せる
  end

  private

  def set_plan
    @plan = current_user.plans.find(params[:plan_id])
  end
end