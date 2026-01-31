module Api
  class AiAreaController < ApplicationController
    before_action :authenticate_user!
    before_action :set_plan

    # AI提案を生成（プランモード/スポットモード両対応）
    def suggest
      @area_data = {
        center_lat: params[:center_lat].to_f,
        center_lng: params[:center_lng].to_f,
        radius_km: params[:radius_km].to_f
      }

      @mode = params[:mode] || "plan"

      @result = AiAreaService.suggest(
        plan: @plan,
        center_lat: @area_data[:center_lat],
        center_lng: @area_data[:center_lng],
        radius_km: @area_data[:radius_km],
        slots: params[:slots] || [],
        mode: @mode,
        genre_id: params[:genre_id]&.to_i,
        count: params[:count]&.to_i
      )

      # area_data を結果に含めて保存（履歴表示時に復元するため）
      @result[:area_data] = @area_data
      @result[:mode] = @mode

      # AIメッセージとして保存
      @plan.ai_chat_messages.create!(
        user: current_user,
        role: "assistant",
        content: @result.to_json
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_plan_path(@plan) }
      end
    end

    # 終了（モード選択UIを再表示）
    def finish
      # 最新メッセージが既にmode_selectなら何もしない
      last_message = @plan.ai_chat_messages.order(created_at: :desc).first
      if last_message&.response_type == "mode_select"
        head :no_content
        return
      end

      @result = {
        type: "mode_select",
        message: "他にお手伝いできることはありますか？"
      }

      @plan.ai_chat_messages.create!(
        user: current_user,
        role: "assistant",
        content: @result.to_json
      )

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to edit_plan_path(@plan) }
      end
    end

    private

    def set_plan
      @plan = current_user.plans.find(params[:plan_id])
    end
  end
end
