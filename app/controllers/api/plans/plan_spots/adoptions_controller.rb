# app/controllers/api/plans/plan_spots/adoptions_controller.rb
module Api
  module Plans
    module PlanSpots
      class AdoptionsController < BaseController
        before_action :set_plan

        # プランを一括採用（AI提案 / コミュニティプラン共通）
        # POST /api/plan_spots/adopt
        def create
          spot_ids = Array(params[:spots]).map { |s| s["spot_id"] || s[:spot_id] }.compact.map(&:to_i)
          return head :unprocessable_entity if spot_ids.empty?

          @plan.adopt_spots!(spot_ids)
          @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

          respond_to do |format|
            format.turbo_stream { render "plans/refresh_plan_tab" }
            format.json { render json: { success: true } }
          end
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: "スポットが見つかりません" }, status: :not_found
        rescue ActiveRecord::RecordInvalid => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        private

        def set_plan
          # plan_id は body から取得
          @plan = current_user.plans
            .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
            .find(params[:plan_id])
        end
      end
    end
  end
end
