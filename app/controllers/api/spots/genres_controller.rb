# app/controllers/api/spots/genres_controller.rb
module Api
  module Spots
    class GenresController < BaseController
      before_action :set_spot

      # GET /api/spots/:spot_id/genres
      def show
        @spot.detect_genres!
        render partial: "spots/genres", locals: { spot: @spot.reload }
      end

      private

      def set_spot
        @spot = Spot.find(params[:spot_id])
      end
    end
  end
end
