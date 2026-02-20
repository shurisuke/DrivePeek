# コミュニティ一覧（みんなの旅）
#
# プラン/スポットの検索・一覧表示を担当
# Turbo Frame リクエスト時も同じHTMLを返し、CSSでレイアウト調整
#
class CommunityController < ApplicationController
  SORT_OPTIONS = %w[newest oldest popular].freeze

  def index
    set_filter_variables

    # お気に入りフィルターが有効な場合、current_user を渡す（ログイン時のみ）
    liked_by_user = @favorites_only && current_user ? current_user : nil

    # 共通検索条件
    search_params = {
      keyword: params[:q],
      cities: params[:cities],
      genre_ids: params[:genre_ids],
      liked_by_user: liked_by_user,
      circle: @circle,
      sort: @sort
    }

    # 検索タイプに応じてプランまたはスポットを取得
    if @search_type == "spot"
      @community_spots = Spot.for_community(**search_params).page(params[:page]).per(10)

      # スポットカード用データをプリロード（N+1回避）
      preload_data = Spot.preload_card_data(@community_spots, current_user)
      @spot_stats = preload_data[:spot_stats]
      @user_favorite_spots = preload_data[:user_favorite_spots]
    else
      @community_plans = Plan.for_community(**search_params).page(params[:page]).per(10)
    end

    # 件数を計算（検索結果ラベルに表示）
    calculate_counts(search_params)
  end

  private

  def set_filter_variables
    @search_type = params[:search_type] == "spot" ? "spot" : "plan"
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @favorites_only = params[:favorites_only] == "1"
    @sort = SORT_OPTIONS.include?(params[:sort]) ? params[:sort] : "newest"
    @genres_by_category = Genre.grouped_by_category
    @cities_by_prefecture = Spot.cities_by_prefecture

    # 円エリア検索パラメータ
    @circle = circle_params
  end

  # 円エリアパラメータを取得（すべて揃っている場合のみ）
  def circle_params
    center_lat = params[:center_lat].presence&.to_f
    center_lng = params[:center_lng].presence&.to_f
    radius_km = params[:radius_km].presence&.to_f

    return nil unless center_lat && center_lng && radius_km

    { center_lat: center_lat, center_lng: center_lng, radius_km: radius_km }
  end

  # 件数を計算（現在の検索条件での総件数）
  def calculate_counts(search_params)
    @spots_count = Spot.for_community(**search_params).count
    @plans_count = Plan.for_community(**search_params).count
  end
end
