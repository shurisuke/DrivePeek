# コミュニティ一覧（みんなの旅）
#
# プラン/スポットの検索・一覧表示を担当
# 編集画面からは Turbo Frame で読み込まれる
#
class CommunityController < ApplicationController
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
      @community_plans = Plan.for_community(
        keyword: params[:q],
        cities: params[:cities],
        genre_ids: params[:genre_ids],
        liked_by_user: liked_by_user
      ).page(params[:page]).per(10)
    end

    # Turbo Frame リクエストの場合はフレーム用テンプレートを返す
    if turbo_frame_request?
      render partial: "community/results", locals: { turbo_frame: true }
    end
  end

  private

  def set_filter_variables
    @search_type = params[:search_type]
    @search_query = params[:q]
    @selected_cities = Array(params[:cities]).reject(&:blank?)
    @selected_genre_ids = Array(params[:genre_ids]).map(&:to_i).reject(&:zero?)
    @favorites_only = params[:favorites_only] == "1"
    @genres_by_category = Genre.grouped_by_category
    @cities_by_prefecture = Spot.cities_by_prefecture
  end
end
