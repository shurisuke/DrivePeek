class PlansController < ApplicationController
  def index
    @plans = Plan.for_community(
      keyword: params[:q],
      cities: params[:cities],
      genre_ids: params[:genre_ids]
    ).page(params[:page]).per(10)

    set_filter_variables
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

    # みんなのプラン: 編集中のプランを除外
    @community_plans = Plan.for_community(
      keyword: params[:q],
      cities: params[:cities],
      genre_ids: params[:genre_ids]
    ).where.not(id: @plan.id)
      .page(params[:page])
      .per(5)

    set_filter_variables
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
    redirect_back fallback_location: plans_path, notice: "プランを削除しました"
  end

  private

  def plan_params
    params.require(:plan).permit(:title)
  end

  def set_filter_variables
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end