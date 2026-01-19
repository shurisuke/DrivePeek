# frozen_string_literal: true

module Api
  module Map
    class InfowindowsController < BaseController
      # POST /api/map/infowindow
      # InfoWindowのHTMLを返す
      def create
        render partial: "map/infowindow", locals: infowindow_params
      end

      private

      def infowindow_params
        zoom_index = (params[:zoom_index] || MapHelper::INFOWINDOW_DEFAULT_ZOOM_INDEX).to_i
        zoom_scale = MapHelper::INFOWINDOW_ZOOM_SCALES[zoom_index] || "md"

        {
          name: params[:name],
          address: params[:address],
          photo_urls: params[:photo_urls] || [],
          types: params[:types] || [],
          place_id: params[:place_id],
          show_button: params[:show_button].to_s != "false",
          button_label: params[:button_label],
          plan_spot_id: params[:plan_spot_id],
          edit_buttons: parse_edit_buttons,
          zoom_scale: zoom_scale,
          zoom_index: zoom_index
        }
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
    end
  end
end
