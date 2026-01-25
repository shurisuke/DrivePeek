# frozen_string_literal: true

module Api
  # AI提案スポットを既存Spotに紐付けるか、新規作成する
  class AiSpotsController < BaseController
    # POST /api/ai_spots/resolve
    def resolve
      spot = Spot.find_or_create_from_location(
        name: params[:name].to_s.strip,
        address: params[:address].to_s.strip,
        lat: params[:lat].to_f,
        lng: params[:lng].to_f
      )

      if spot
        render json: spot_response(spot)
      else
        render_error("スポットが見つかりませんでした")
      end
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.message)
    end

    # POST /api/ai_spots/resolve_batch
    def resolve_batch
      spots_params = params[:spots] || []
      return render json: { spots: [] } if spots_params.empty?

      results = spots_params.map.with_index do |spot_param, index|
        resolve_spot_with_geocoding(spot_param, index)
      end

      render json: { spots: results }
    end

    private

    def resolve_spot_with_geocoding(spot_param, index)
      name = spot_param[:name].to_s.strip
      address = spot_param[:address].to_s.strip

      geo = ReverseGeocoder.geocode_address(address)
      return { index: index, error: "住所から座標を取得できませんでした" } unless geo

      spot = Spot.find_or_create_from_location(name: name, address: address, lat: geo[:lat], lng: geo[:lng])
      return { index: index, error: "スポットが見つかりませんでした" } unless spot

      spot_response(spot).merge(index: index)
    end

    def spot_response(spot)
      {
        spot_id: spot.id,
        place_id: spot.place_id,
        lat: spot.lat,
        lng: spot.lng
      }
    end

    def render_error(message)
      render json: { error: message }, status: :unprocessable_entity
    end
  end
end
