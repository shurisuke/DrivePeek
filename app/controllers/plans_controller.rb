class PlansController < ApplicationController
  def index
  end

  def show
  end

  def create
    lat = params[:lat]
    lng = params[:lng]

    @plan = PlanSetupService.new(user: current_user, lat: lat, lng: lng).setup
    redirect_to edit_plan_path(@plan)
  rescue => e
    redirect_to authenticated_root_path(@plan), alert: "プランの作成に失敗しました: #{e.message}"
  end

  def edit
    @plan = Plan.includes(:start_point, :goal_point, :plan_spots => :spot).find(params[:id])
  end

  def update
  end

  def destroy
  end
end