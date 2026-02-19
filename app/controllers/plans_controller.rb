class PlansController < ApplicationController
  SORT_OPTIONS = %w[newest oldest].freeze

  before_action :authenticate_user!, except: %i[show]

  def index
    set_filter_variables

    @plans = current_user.plans
      .exclude_stale_empty
      .search_keyword(@search_query)
      .filter_by_cities(@selected_cities)
      .filter_by_genres(@selected_genre_ids)
      .includes(:start_point, plan_spots: { spot: :genres })
      .sort_by_option(@sort)
      .page(params[:page])
      .per(10)

    @plans_count = @plans.total_count
  end

  def show
    @plan = Plan.publicly_visible
                .includes(:user, :start_point, :goal_point, plan_spots: { spot: :genres })
                .find(params[:id])
    @related_plans = @plan.related_plans(limit: 5)
  end

  def new
    @latest_plan = current_user.plans.order(updated_at: :desc).first
  end

  def create
    lat = params[:lat]
    lng = params[:lng]

    @plan = Plan.create_with_location(user: current_user, lat: lat, lng: lng)

    # プラン詳細画面「このプランで作る」ボタン
    if params[:copy_from].present?
      source = Plan.publicly_visible.find_by(id: params[:copy_from])
      @plan.copy_spots_from(source) if source
    end

    # スポット詳細画面「ここからプランを作る」ボタン
    if params[:add_spot].present?
      spot = Spot.find_by(id: params[:add_spot])
      if spot
        @plan.plan_spots.create!(spot: spot)
        @plan.recalculate_for!(nil, action: :create)
      end
    end

    redirect_to edit_plan_path(@plan)
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
    @sort = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "newest"
    @genres_by_category = Genre.grouped_by_category
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
