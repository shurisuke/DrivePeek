class PlansController < ApplicationController
  def index
    set_filter_variables

    # 検索タイプに応じてプランまたはスポットを取得
    if @search_type == "spot"
      @community_spots = Spot.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids]
      ).page(params[:page]).per(10)
    else
      @plans = Plan.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids]
      ).page(params[:page]).per(10)
    end
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
    @plan = Plan.includes(:start_point, :goal_point, plan_spots: :spot).find(params[:id])

    set_filter_variables

    # 検索タイプに応じてプランまたはスポットを取得
    if @search_type == "spot"
      @community_spots = Spot.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids]
      ).page(params[:page]).per(10)
    else
      @community_plans = Plan.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids]
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
    @genres = Genre.ordered
    @cities_by_prefecture = Spot.cities_by_prefecture
  end

  # スポットIDからお気に入り情報を取得するハッシュを生成
  def like_spots_by_spot_id(spots)
    return {} unless current_user

    spot_ids = spots.map(&:id)
    current_user.like_spots.where(spot_id: spot_ids).index_by(&:spot_id)
  end
  helper_method :like_spots_by_spot_id

  # プランIDからお気に入り情報を取得するハッシュを生成
  def like_plans_by_plan_id(plans)
    return {} unless current_user

    plan_ids = plans.map(&:id)
    current_user.like_plans.where(plan_id: plan_ids).index_by(&:plan_id)
  end
  helper_method :like_plans_by_plan_id
end
