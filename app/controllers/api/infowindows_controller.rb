# frozen_string_literal: true

module Api
  class InfowindowsController < BaseController
    # GET /api/infowindow
    # Turbo Frame用：spotId または place_id でInfoWindow HTMLを返す
    # Google API は1回のみ呼び出し（photos 取得）
    def show
      @edit_mode = params[:edit_mode]

      # 出発・帰宅地点の場合はシンプルなパーシャルを返す
      if @edit_mode.present?
        return render partial: "map/infowindow_home", locals: home_locals
      end

      @spot = find_or_create_spot
      @photo_urls = fetch_photo_urls
      @show_button = params[:show_button].to_s != "false"
      @button_label = params[:button_label]
      @plan_spot_id = find_plan_spot_id

      render partial: "map/infowindow_spot", locals: infowindow_locals
    end

    # POST /api/infowindow
    # JS fetch用（既存互換：クライアントから photo_urls を受け取る）
    def create
      @place_details = nil
      @spot = find_or_create_spot
      @photo_urls = params[:photo_urls] || []
      @show_button = params[:show_button].to_s != "false"
      @button_label = params[:button_label]
      @plan_spot_id = find_plan_spot_id
      @edit_buttons = parse_edit_buttons

      render partial: "map/infowindow_spot", locals: infowindow_locals
    end

    private

    def find_or_create_spot
      # spot_idが指定されていれば既存spotを返す
      return Spot.find(params[:spot_id]) if params[:spot_id].present?

      # place_idで検索/作成
      return nil if params[:place_id].blank?

      spot = Spot.find_or_initialize_by(place_id: params[:place_id])

      if spot.new_record?
        # Google API で name/address を取得
        @place_details = PlaceDetailsService.fetch(place_id: params[:place_id], include_photos: true)
        spot.assign_attributes(spot_params)
        spot.save!
      end

      spot
    end

    def spot_params
      name = @place_details&.dig(:name) || params[:name]
      address = @place_details&.dig(:address) || params[:address]

      {
        name: name || "名称不明",
        address: address || "住所不明",
        lat: params[:lat],
        lng: params[:lng]
      }
    end

    # 写真URLを取得（spotId/placeId どちらでも対応）
    def fetch_photo_urls
      # 新規spot作成時は @place_details から取得済み
      return @place_details[:photo_urls] if @place_details&.dig(:photo_urls).present?

      # 既存spotの場合、place_id で写真を取得
      place_id = @spot&.place_id || params[:place_id]
      return [] if place_id.blank?

      details = PlaceDetailsService.fetch(place_id: place_id, include_photos: true)
      details&.dig(:photo_urls) || []
    end

    def find_plan_spot_id
      return nil unless user_signed_in?

      plan_id = params[:plan_id]
      return nil unless plan_id.present?

      plan = current_user.plans.find_by(id: plan_id)
      return nil unless plan

      # spotId で検索
      if params[:spot_id].present?
        plan_spot = plan.plan_spots.find_by(spot_id: params[:spot_id])
        return plan_spot&.id if plan_spot
      end

      # placeId で検索
      if params[:place_id].present?
        plan_spot = plan.plan_spots.joins(:spot).find_by(spots: { place_id: params[:place_id] })
        return plan_spot&.id
      end

      nil
    end

    def parse_edit_buttons
      buttons = params[:edit_buttons]
      return [] if buttons.blank?

      buttons.map do |btn|
        {
          id: btn[:id],
          label: btn[:label],
          variant: btn[:variant],
          action: btn[:action]
        }
      end
    end

    def home_locals
      zoom_index = (params[:zoom_index] || MapHelper::INFOWINDOW_DEFAULT_ZOOM_INDEX).to_i
      zoom_scale = MapHelper::INFOWINDOW_ZOOM_SCALES[zoom_index] || "md"

      # DBから住所を取得
      plan = Plan.find_by(id: params[:plan_id])
      point = @edit_mode == "start_point" ? plan&.start_point : plan&.goal_point
      address = point&.address

      {
        name: params[:name],
        address: address,
        edit_mode: @edit_mode,
        zoom_scale: zoom_scale,
        plan_id: params[:plan_id]
      }
    end

    def infowindow_locals
      zoom_index = (params[:zoom_index] || MapHelper::INFOWINDOW_DEFAULT_ZOOM_INDEX).to_i
      zoom_scale = MapHelper::INFOWINDOW_ZOOM_SCALES[zoom_index] || "md"

      {
        spot: @spot,
        photo_urls: @photo_urls,
        show_button: @show_button,
        button_label: @button_label,
        plan_id: params[:plan_id],
        plan_spot_id: @plan_spot_id,
        edit_mode: @edit_mode,
        zoom_scale: zoom_scale,
        zoom_index: zoom_index
      }
    end
  end
end
