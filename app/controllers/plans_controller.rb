class PlansController < ApplicationController
  before_action :authenticate_user!, except: %i[index show]

  def index
    set_filter_variables

    # お気に入りフィルターが有効な場合、current_user を渡す（ログイン時のみ）
    liked_by_user = @favorites_only && current_user ? current_user : nil

    # 検索タイプに応じてプランまたはスポットを取得
    if @search_type == "spot"
      @community_spots = Spot.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids],
        liked_by_user: liked_by_user
      ).page(params[:page]).per(10)
    else
      @plans = Plan.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids],
        liked_by_user: liked_by_user
      ).page(params[:page]).per(10)
    end
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

    set_filter_variables

    # お気に入りフィルターが有効な場合、current_user を渡す
    liked_by_user = @favorites_only ? current_user : nil

    # 検索タイプに応じてプランまたはスポットを取得
    if @search_type == "spot"
      @community_spots = Spot.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids],
        liked_by_user: liked_by_user
      ).page(params[:page]).per(10)
    else
      @community_plans = Plan.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids],
        liked_by_user: liked_by_user
      ).where.not(id: @plan.id)
        .page(params[:page])
        .per(6)
    end
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
    @search_type = params[:search_type]
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @favorites_only = params[:favorites_only] == "1"
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
