# app/controllers/api/previews_controller.rb
module Api
  class PreviewsController < Api::BaseController
    # GET /api/preview?plan_id=:id
    def show
      plan = Plan.publicly_visible
                 .includes(plan_spots: { spot: :genres })
                 .find(params[:plan_id])

      render json: plan.preview_data
    end
  end
end
