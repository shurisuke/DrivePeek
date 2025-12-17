# app/controllers/plan_spots/toll_usages_controller.rb
module PlanSpots
  class TollUsedController < ApplicationController
    before_action :authenticate_user!
    before_action :set_plan
    before_action :set_plan_spot

    # PATCH /plans/:plan_id/plan_spots/:id/update_toll_used
    def update
      toll_used = ActiveModel::Type::Boolean.new.cast(params[:toll_used])

      if @plan_spot.update(toll_used: toll_used)
        render json: {
          plan_spot_id: @plan_spot.id,
          toll_used: @plan_spot.toll_used
        }, status: :ok
      else
        render json: {
          message: "有料道路の設定更新に失敗しました",
          details: @plan_spot.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def set_plan
      @plan = current_user.plans.find(params[:plan_id])
    end

    def set_plan_spot
      @plan_spot = @plan.plan_spots.find(params[:id])
    end
  end
end