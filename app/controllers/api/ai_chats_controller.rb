module Api
  class AiChatsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_plan

    def create
      @user_message = params[:message].to_s.strip
      return head :unprocessable_entity if @user_message.blank?

      @ai_response = AiChatService.chat(@user_message, plan: @plan)

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
