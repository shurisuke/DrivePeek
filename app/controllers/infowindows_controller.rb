# frozen_string_literal: true

# InfoWindowは認証不要（公開プラン閲覧時にも使用）
# ログイン状態に応じてUIを出し分ける
# createのみ認証必須（スポット作成・API呼び出しコスト保護）
class InfowindowsController < ApplicationController
  before_action :authenticate_user!, only: :create
  # GET /infowindow
  # Turbo Frame用：spotId または place_id でInfoWindow HTMLを返す
  def show
    return render_guest unless user_signed_in?
    return render_home if edit_mode?
    render_spot
  end

  # POST /infowindow
  # JS fetch用（既存互換：クライアントから photo_urls を受け取る）
  def create
    @place_details = nil
    @spot = find_or_create_spot
    @photo_urls = params[:photo_urls] || []
    @show_button = params[:show_button].to_s != "false"
    @button_label = params[:button_label]
    @map_mode = params[:map_mode]
    @plan_spot_id = find_plan_spot_id

    render partial: "map/infowindow_spot", locals: infowindow_locals
  end

  private

  def render_guest
    render partial: "map/infowindow_guest", locals: guest_locals
  end

  def render_home
    partial = mobile? ? "map/infowindow_home_mobile" : "map/infowindow_home"
    render partial: partial, locals: home_locals
  end

  def render_spot
    @spot = find_or_create_spot
    @photo_urls = fetch_photo_urls
    @show_button = params[:show_button].to_s != "false"
    @button_label = params[:button_label]
    @map_mode = params[:map_mode]
    @plan_spot_id = find_plan_spot_id

    partial = mobile? ? "map/infowindow_spot_mobile" : "map/infowindow_spot"
    locals = mobile? ? infowindow_locals_mobile : infowindow_locals
    render partial: partial, locals: locals
  end

  def edit_mode?
    params[:edit_mode].present?
  end

  def mobile?
    params[:mobile] == "true"
  end

  def zoom_index
    @zoom_index ||= (params[:zoom_index] || MapHelper::INFOWINDOW_DEFAULT_ZOOM_INDEX).to_i
  end

  def zoom_scale
    @zoom_scale ||= MapHelper::INFOWINDOW_ZOOM_SCALES[zoom_index] || "md"
  end

  def find_or_create_spot
    # spot_idが指定されていれば既存spotを返す
    return Spot.find(params[:spot_id]) if params[:spot_id].present?

    # place_idで検索/作成
    return nil if params[:place_id].blank?

    spot = Spot.find_or_initialize_by(place_id: params[:place_id])

    if spot.new_record?
      # Google API で name/address を取得
      @place_details = Spot::GoogleClient.fetch_details(params[:place_id], include_photos: true)
      spot.update!(
        name: @place_details&.dig(:name) || params[:name] || "名称不明",
        address: @place_details&.dig(:address) || params[:address] || "住所不明",
        lat: params[:lat],
        lng: params[:lng]
      )
    end

    spot
  end

  # 写真URLを取得（spotId/placeId どちらでも対応）
  def fetch_photo_urls
    # 新規spot作成時は @place_details から取得済み
    return @place_details[:photo_urls] if @place_details&.dig(:photo_urls).present?

    # 既存spotの場合、place_id で写真を取得
    place_id = @spot&.place_id || params[:place_id]
    return [] if place_id.blank?

    details = Spot::GoogleClient.fetch_details(place_id, include_photos: true)
    details&.dig(:photo_urls) || []
  end

  def find_plan_spot_id
    return unless user_signed_in? && params[:plan_id].present?

    plan = current_user.plans.find_by(id: params[:plan_id])
    return unless plan

    if params[:spot_id].present?
      plan.plan_spots.find_by(spot_id: params[:spot_id])&.id
    elsif params[:place_id].present?
      plan.plan_spots.joins(:spot).find_by(spots: { place_id: params[:place_id] })&.id
    end
  end

  def home_locals
    # DBから住所を取得（自分のプラン → 公開プランの順で検索）
    plan = current_user.plans.find_by(id: params[:plan_id]) ||
           Plan.publicly_visible.find_by(id: params[:plan_id])
    point = params[:edit_mode] == "start_point" ? plan&.start_point : plan&.goal_point

    {
      name: params[:name],
      address: point&.address,
      edit_mode: params[:edit_mode],
      zoom_scale: zoom_scale,
      plan_id: params[:plan_id]
    }
  end

  def guest_locals
    { zoom_scale: zoom_scale, zoom_index: zoom_index }
  end

  def infowindow_locals
    {
      spot: @spot,
      photo_urls: @photo_urls,
      show_button: @show_button,
      button_label: @button_label,
      map_mode: @map_mode,
      plan_id: params[:plan_id],
      plan_spot_id: @plan_spot_id,
      edit_mode: params[:edit_mode],
      zoom_scale: zoom_scale,
      zoom_index: zoom_index,
      default_tab: params[:default_tab]
    }
  end

  def infowindow_locals_mobile
    {
      spot: @spot,
      photo_urls: @photo_urls,
      show_button: @show_button,
      map_mode: @map_mode,
      plan_id: params[:plan_id],
      plan_spot_id: @plan_spot_id,
      default_tab: params[:default_tab]
    }
  end
end
