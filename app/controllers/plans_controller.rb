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

    # みんなのプラン: 公開ユーザーのスポットありプランを取得（ページネーション対応）
    @community_plans = Plan
      .publicly_visible
      .with_spots
      .where.not(id: @plan.id)
      .includes(:user, :start_point, plan_spots: :spot)
      .preload(user: { user_spots: :tags })
      .order(updated_at: :desc)
      .page(params[:page])
      .per(5)
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

  private

  def plan_params
    params.require(:plan).permit(:title)
  end

  def destroy
  end
end