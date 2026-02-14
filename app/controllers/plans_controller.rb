class PlansController < ApplicationController
  before_action :authenticate_user!, except: %i[show]

  def index
    set_filter_variables

    @plans = current_user.plans
      .exclude_stale_empty
      .search_keyword(@search_query)
      .filter_by_cities(@selected_cities)
      .filter_by_genres(@selected_genre_ids)
      .includes(:start_point, plan_spots: { spot: :genres })
      .order(updated_at: :desc)
      .page(params[:page])
      .per(10)
  end

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

  def set_filter_variables
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @genres_by_category = Genre.grouped_by_category
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
