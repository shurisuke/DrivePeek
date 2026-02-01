class PlansController < ApplicationController
  before_action :authenticate_user!, except: %i[show]

  def show
    @plan = Plan.publicly_visible
                .includes(:user, :start_point, :goal_point, plan_spots: { spot: :genres })
                .find(params[:id])
  end

  def new
    @latest_plan = current_user.plans.order(updated_at: :desc).first
  end

  def create
    lat = params[:lat]
    lng = params[:lng]

    @plan = Plan.create_with_location(user: current_user, lat: lat, lng: lng)
    redirect_to edit_plan_path(@plan)
  rescue => e
    redirect_to authenticated_root_path(@plan), alert: "プランの作成に失敗しました: #{e.message}"
  end

  def edit
    @plan = current_user.plans.includes(:start_point, :goal_point, plan_spots: :spot).find(params[:id])
  end

  def update
    @plan = current_user.plans.find(params[:id])

    if @plan.update(plan_params)
      respond_to do |format|
        format.html { redirect_to edit_plan_path(@plan), notice: "プランを保存しました" }
        format.json { render json: { success: true, message: "プランを保存しました" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to edit_plan_path(@plan), alert: "保存に失敗しました" }
        format.json { render json: { success: false, errors: @plan.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @plan = current_user.plans.find(params[:id])
    @plan.destroy!
    redirect_back fallback_location: community_path, notice: "プランを削除しました"
  end

  private

  def plan_params
    params.require(:plan).permit(:title)
  end
end
