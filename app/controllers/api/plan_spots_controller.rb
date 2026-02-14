# app/controllers/api/plan_spots_controller.rb
module Api
  class PlanSpotsController < BaseController
    before_action :set_plan, only: %i[create]
    before_action :set_plan_spot, only: %i[update]

    # POST /api/plan_spots
    def create
      @spot = Spot.find(params[:spot_id])
      @plan_spot = @plan.plan_spots.create!(spot: @spot)

      @plan.recalculate_for!(@plan_spot, action: :create)
      @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

      respond_to do |format|
        format.turbo_stream { render "plans/refresh_plan_tab" }
      end
    rescue ActiveRecord::RecordNotFound
      render json: { message: "スポットが見つかりません" }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: e.message }, status: :unprocessable_entity
    end

    # PATCH /api/plan_spots/:id
    # toll_used, memo, stay_duration を統合
    def update
      @plan_spot.update!(plan_spot_params)

      # toll_used は経路再計算、stay_duration はスケジュール再計算
      # パラメータの存在で判断（saved_changes に依存しない）
      if params.key?(:toll_used)
        @plan.recalculate_for!(@plan_spot, action: :reorder)
      elsif params.key?(:stay_duration)
        @plan.recalculate_for!(@plan_spot, action: :update)
      end

      @plan = Plan.includes(:start_point, :goal_point, plan_spots: { spot: :genres }).find(@plan.id)

      respond_to do |format|
        format.turbo_stream { render "plans/refresh_plan_tab" }
      end
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: "更新に失敗しました", details: e.record.errors.full_messages }, status: :unprocessable_entity
    end

    private

    def set_plan
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(params[:plan_id])
    end

    def set_plan_spot
      @plan_spot = PlanSpot.find(params[:id])
      @plan = current_user.plans
        .includes(:start_point, :goal_point, plan_spots: { spot: :genres })
        .find(@plan_spot.plan_id)
    end

    def plan_spot_params
      params.permit(:toll_used, :memo, :stay_duration)
    end
  end
end
