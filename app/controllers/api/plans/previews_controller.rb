# app/controllers/api/plans/previews_controller.rb
module Api
  module Plans
    class PreviewsController < Api::BaseController
      # GET /api/plans/:plan_id/preview
      def show
        plan = Plan.publicly_visible
                   .includes(plan_spots: { spot: :genres })
                   .find(params[:plan_id])

        render json: plan.preview_data
      end
    end
  end
end
